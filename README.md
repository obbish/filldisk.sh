### What it looks like

```

:~$ sudo ./filldisk.sh

Writing to /dev/sda...
Generating temp bulk file in RAM...

========== WRITE PLAN ==========
Device size:                 476940 MB
Block size:                  4096 KB
Source file size:            1736 bytes
Bulk file size:              134217104 bytes
Full bulk writes:            3726
Ending file size:            14929600 bytes
Zero padding (if needed):    1376 bytes
Total source iterations:     288080564
================================

Proceed with destructive write to /dev/sda? Type 'yes':

```

### What it's for

When you have a short file that you want repeated over a disk.

### What it does

Script repeats your short file into a larger temp file in RAM.

### What more

Also makes a smaller temp file to fill up the last blocks. 

### What else

Ends by padding the final blocks with zero.

### What

It's a copy organized into three dd operations to maximize resource usage.
