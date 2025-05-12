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

Proceed with destructive write to /dev/sda? Type 'yes': yes
Writing 3726 bulk chunks...
500086865920 bytes (500 GB, 466 GiB) copied, 4662 s, 107 MB/s500093028999 bytes (500 GB, 466 GiB) copied, 4662.25 s, 107 MB/s

119231+1 records in
119231+1 records out
500093028999 bytes (500 GB, 466 GiB) copied, 4662.27 s, 107 MB/s
Writing ending file...
dd: error writing '/dev/sda': Invalid argument
1+0 records in
0+0 records out
0 bytes copied, 0.000223557 s, 0.0 kB/s
Writing 1376 bytes of zero padding...
dd: error writing '/dev/sda': Invalid argument
1+0 records in
0+0 records out
0 bytes copied, 0.000127586 s, 0.0 kB/s
✅ Operation complete.

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
