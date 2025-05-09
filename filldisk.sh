#!/bin/bash

# CONFIGURATION
SOURCE_FILE="source.txt"
TEMP_SIZE_MB=128                          # Size of the bulk file in MB
BLOCK_SIZE=4194304                        # 4MB block size in bytes
TARGET_DEVICE="/dev/sda"

echo "Writing to $TARGET_DEVICE"

# === 1. Size Calculations ===

# File sizes
SOURCE_SIZE=$(stat -c%s "$SOURCE_FILE")
TEMP_FILE_SIZE=$((TEMP_SIZE_MB * 1024 * 1024))

# Device size
DEVICE_SIZE=$(blockdev --getsize64 "$TARGET_DEVICE")

# How many source copies in temp file
COPIES_PER_TEMP=$((TEMP_FILE_SIZE / SOURCE_SIZE))

# Actual temp file generation
echo "Generating temp bulk file in RAM..."
TEMP_FILE="/dev/shm/temp_bulk_file"
> "$TEMP_FILE"
for ((i = 0; i < COPIES_PER_TEMP; i++)); do
  cat "$SOURCE_FILE" >> "$TEMP_FILE"
done
ACTUAL_TEMP_SIZE=$(stat -c%s "$TEMP_FILE")

# Full iterations of bulk file on disk
FULL_BULK_WRITES=$((DEVICE_SIZE / ACTUAL_TEMP_SIZE))
WRITTEN_BYTES=$((FULL_BULK_WRITES * ACTUAL_TEMP_SIZE))
REMAINING_BYTES=$((DEVICE_SIZE - WRITTEN_BYTES))

# Ending file generation
COPIES_IN_ENDING=$((REMAINING_BYTES / SOURCE_SIZE))
ENDING_FILE="/dev/shm/ending_file"
> "$ENDING_FILE"
for ((i = 0; i < COPIES_IN_ENDING; i++)); do
  cat "$SOURCE_FILE" >> "$ENDING_FILE"
done
ENDING_FILE_SIZE=$(stat -c%s "$ENDING_FILE")

# Zero fill calculation
TOTAL_WRITTEN=$((WRITTEN_BYTES + ENDING_FILE_SIZE))
PADDING_BYTES=$((DEVICE_SIZE - TOTAL_WRITTEN))

# === 2. Report ===

echo
echo "========== WRITE PLAN =========="
echo "Device size:                 $((DEVICE_SIZE / 1024 / 1024)) MB"
echo "Block size:                  $((BLOCK_SIZE / 1024)) KB"
echo "Source file size:            $SOURCE_SIZE bytes"
echo "Bulk file size:              $ACTUAL_TEMP_SIZE bytes"
echo "Full bulk writes:            $FULL_BULK_WRITES"
echo "Ending file size:            $ENDING_FILE_SIZE bytes"
echo "Zero padding (if needed):    $PADDING_BYTES bytes"
echo "Total source iterations:     $((FULL_BULK_WRITES * COPIES_PER_TEMP + COPIES_IN_ENDING))"
echo "================================"
echo

read -p "Proceed with destructive write to $TARGET_DEVICE? Type 'yes': " CONFIRM
[[ "$CONFIRM" != "yes" ]] && echo "Aborted." && exit 1

# === 3. Writing Steps ===

# 1. Bulk write
echo "Writing $FULL_BULK_WRITES bulk chunks..."
seq 1 "$FULL_BULK_WRITES" | while read -r i; do
  echo "Writing chunk $i/$FULL_BULK_WRITES..."
  cat "$TEMP_FILE"
done | dd of="$TARGET_DEVICE" bs=$BLOCK_SIZE iflag=fullblock oflag=direct conv=fdatasync status=progress

# 2. Ending write
if [ "$COPIES_IN_ENDING" -gt 0 ]; then
  echo "Writing ending file..."
  cat "$ENDING_FILE" | dd of="$TARGET_DEVICE" bs=$BLOCK_SIZE seek=$((WRITTEN_BYTES / BLOCK_SIZE)) iflag=fullblock oflag=direct conv=fdatasync status=progress
fi

# 3. Zero pad if needed
if [ "$PADDING_BYTES" -gt 0 ]; then
  echo "Writing $PADDING_BYTES bytes of zero padding..."
  dd if=/dev/zero bs=1 count="$PADDING_BYTES" | dd of="$TARGET_DEVICE" bs=1 seek=$TOTAL_WRITTEN oflag=direct conv=fdatasync status=progress
fi

echo "✅ Operation complete."
