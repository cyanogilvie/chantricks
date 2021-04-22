% chantricks(n) 1.0 | Sugar for Tcl channels
% Cyan Ogilvie
% 1.0

# NAME

chantricks - Sugar for Tcl channels

# SYNOPSIS

**package require chantricks** ?1.0?

**chantricks::with_chan** *handlevar* *create_script* *use_script*

**chantricks::with_file** *handlevar* *filename* ?mode? *script*

**chantricks::readfile** *filename*

**chantricks::readbin** *filename*

**chantricks::writefile** *filename* *chars*

**chantricks::writebin** *filename* *bytes*

**chantricks::appendfile** *filename* *chars*

**chantricks::appendbin** *filename* *bytes*

**chantricks::tap_chan** *chan* ?cb? ?name?

# DESCRIPTION

A collection of useful utility functions for Tcl channels.  The Tcl commands
for interacting with channels are elegant and general, but very common use
cases like reading a file are somewhat fraught and prone to subtle failures if
the user doesn't take care: open file handles can easily leak if a command
throws an exception between the **open** and the corresponding **close**, for
instance.  Users must also take care that the translation and encoding of the
created channel is correct for their use case (binary for loading an image for
example).  These utility procs provide some syntactic sugar to support the
common use cases for dealing with files and channels.

# COMMANDS

**chantricks::with_chan** *handlevar* *create_script* *use_script*
:   Execute *use_script* in the current frame, with the channel handle produced
    by *create_script* available as the variable *handlevar*.  When
    *use_script* terminates (via any return type) the channel is closed before
    returning the result of the script, or re-throwing the exception it threw.

**chantricks::with_file** *handlevar* *filename* ?mode? *script*
:   Execute *script* in the current frame, with the channel handle opened
    to the file *filename* using the mode *mode* (as interpreted by **open**).
    If *mode* isn't supplied it defaults to "r".

**chantricks::readfile** *filename*
:   Return the contents of *filename* as text, in the system encoding.

**chantricks::readbin** *filename*
:   Return the contents of *filename* as binary data.

**chantricks::writefile** *filename* *chars*
:   Write *chars* to *filename* as text, in the system encoding.

**chantricks::writebin** *filename* *bytes*
:   Write *bytes* to *filename* as binary data.

**chantricks::appendfile** *filename* *chars*
:   Append *chars* to *filename* as text, in the system encoding.

**chantricks::appendbin** *filename* *bytes*
:   Append *bytes* to *filename* as binary data.

**chantricks::tap_chan** *chan* ?cb? ?name?
:   Intercept reads and writes to *chan*, which call *cb* for each read and
    write on that channel.  If *cb* isn't specified, log the reads and writes
    to stderr with a timestamp and hex encoded data.  Optionally supply a
    friendly name for *chan* as *name*.  If *name* isn't specified, it defaults
    to *chan*.  Each time the channel is read from, written to, or closed *cb*
    is executed, appending the arguments *chan* (the Tcl channel handle),
    *name* (the friendly name supplied for this channel), *op* (one of:
    read, write, finalize), and *bytes* (for read and write).

# EXAMPLES

Read a file as text in the default system encoding:

~~~tcl
set chars   [chantricks readfile /foo/bar]
~~~

Which is equivalent to:

~~~tcl
set chars   [chantricks with_file h /foo/bar {read $h}]
# or
chantricks with_file h /foo/bar {
    set chars   [read $h]
}
~~~

Read a binary image file:

~~~tcl
set bytes   [chantricks readbin /foo/bar.jpg]
~~~

Work with a file using fancy POSIX flags (write to a file, but only if it
didn't previously exist):

~~~tcl
with_file h /tmp/foo {WRONLY CREAT EXCL} {
    puts $h "hello, new file"
}
~~~

Open a socket to a local HTTP server and read the result, ensuring the socket
channel doesn't leak if there is an error:

~~~tcl
set server  localhost
set path    /

chantricks with_chan h {socket $server 80} {
    puts $h "GET $path HTTP/1.0"
    flush $h
    set response [read $h]
}

puts "Got HTTP response:\n$response"
~~~

A slightly more sophisticated HTTP client:

~~~tcl
proc http {method server path {port 80}} {
    chantricks with_chan h {
        if {$port == 443} {
            package require tls
            tls::socket $server $port
        } else {
            socket $server $port
        }
    } {
        chan configure $h -translation {auto crlf} -encoding ascii
        puts $h "[string toupper $method] $path HTTP/1.1\nHost: $server\nConnection: close\n"
        flush $h

        if {![regexp {^HTTP/[0-9]+\.[0-9]+ ([0-9]{3}) (.*)$} [gets $h] - status msg} {
            # Note that it's ok to just throw an error - the socket channel will be closed
            error "Couldn't parse response status line"
        }

        switch -glob $status {
            2* {}
            default {
                error "Server returned unexpected status $status: $msg"
            }
        }

        set headers ""
        while {[set line [gets $h]] ne ""} {
            append headers $line \n
        }

        # Read and return the response body
        chan configure $h -translation binary
        list $status $headers [read $h]
    }
}

lassign [http GET localhost /] status raw_headers raw_body
~~~

Open a file as a temporary disk-backed buffer (perhaps because data to be processed
is too large to fit in memory), write a series of binary chunks from stdin,
seek back to the start and read off lines in utf-8 encoding:

~~~tcl
with_chan h {file tempfile} {
    chan configure $h -translation binary
    chan configure stdin -translation binary
    while {![eof stdin]} {
        puts -nonewline $h [read stdin 1048576]
    }
    close stdin

    seek $h 0
    chan configure $h -translation lf -encoding utf-8
    while {![set line [gets $h]; eof $h]} {
        # Do something with $line
    }
}
~~~

Open a command pipeline, write binary data to it and read the result:

~~~tcl
proc md5 bytes {
    with_chan h {open |[list md5sum --binary] rb+} {
        puts -nonewline $h $bytes
        close $h write
        lindex [read $h] 0
    }
}
~~~

# LICENSE

This package is Copyright 2021 Cyan Ogilvie, and is made available under
the same license terms as the Tcl Core.
