"""
Windows shim for fcntl — file locking no-op for local single-user use.
On Windows there's no risk of concurrent write contention for a local server.
"""
import sys

if sys.platform != "win32":
    raise ImportError("This shim is Windows-only; real fcntl should be used on Unix")

LOCK_SH = 1
LOCK_EX = 2
LOCK_NB = 4
LOCK_UN = 8


def flock(fd, operation):
    pass
