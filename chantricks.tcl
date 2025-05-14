namespace eval ::chantricks {
	namespace export {*}{
		with_chan
		with_file
		readfile
		readbin
		writefile
		writebin
		appendfile
		appendbin
		tap_chan
	}
	namespace ensemble create -prefixes no

	proc with_chan {handlevar create use} { #<<<
		upvar 1 $handlevar h

		set h	[uplevel 1 $create]
		try {
			uplevel 1 $use
		} on return {r o} - on break {r o} - on continue {r o} {
			dict incr o -level 1
			return -options $o $r
		} finally {
			if {$h in [chan names]} {
				catch {close $h}
			}
		}
	}

	#>>>
	proc with_file {handlevar fn args} { #<<<
		switch -- [llength $args] {
			1 {
				set mode	r
				lassign $args script
			}
			2 {
				lassign $args mode script
			}
			default {
				error "Wrong # of args, must be handlevar fn ?mode? script"
			}
		}

		tailcall with_chan $handlevar [list open $fn $mode] $script
	}

	#>>>
	proc readfile fn { # Read a file in text mode (with the system / default encoding) <<<
		with_file h $fn {read $h}
	}

	#>>>
	proc readbin fn { # Read a file in binary mode <<<
		with_file h $fn rb {read $h}
	}

	#>>>
	proc writefile {fn chars} { # Write a file in text mode (with the system / default encoding) <<<
		with_file h $fn w {puts -nonewline $h $chars}
	}

	#>>>
	proc writebin {fn bytes} { # Write a file in binary mode <<<
		with_file h $fn wb {puts -nonewline $h $bytes}
	}

	#>>>
	proc appendfile {fn chars} { # Append to a file in text mode (with the system / default encoding) <<<
		with_file h $fn a {puts -nonewline $h $chars}
	}

	#>>>
	proc appendbin {fn bytes} { # Append to a file in binary mode <<<
		with_file h $fn ab {puts -nonewline $h $bytes}
	}

	#>>>

	proc tap_chan {chan {cb {}} {name {}}} { # Add a tap to a chan to intercept the reads and writes <<<
		if {$cb eq {}} {
			set cb [list apply {
				{name chan op args} {
					set ts		[clock microseconds]
					set s		[expr {$ts / 1000000}]
					set tail	[string trimleft [format %.6f [expr {($ts % 1000000) / 1e6}]] 0]
					set ts_str	[clock format $s -format %Y-%m-%dT%H:%M:%S -timezone :UTC]${tail}Z
					switch -exact -- $op {
						read - write {
							lassign $args bytes
							puts stderr "$ts_str $op $name [binary encode hex $bytes]"
						}
						initialize - finalize - drain - flush - clear {
							puts stderr "$ts_str $op $name"
						}
						default {
							puts stderr "$ts_str $op $name (unexpected)"
						}
					}
				}
			}]
		}
		if {$name eq {}} {set name $chan}
		chan push $chan [list ::chantricks::tapchan $cb $name]
	}

	#>>>

	namespace eval tapchan { # tap chan handler <<<
		namespace export *
		namespace ensemble create -prefixes no -parameters {cb name} -map {
			read	_read
		} -subcommands {
			initialize
			finalize
			read
			write
			drain
			flush
			clear
		}

		proc initialize {cb name chan mode} { #<<<
			{*}$cb $name $chan initialize
			return {initialize finalize read write drain flush clear}
		}

		#>>>
		proc finalize {cb name chan} { #<<<
			{*}$cb $name $chan finalize
		}

		#>>>
		proc clear {cb name chan} { #<<<
			{*}$cb $name $chan clear
		}

		#>>>
		proc _read {cb name chan bytes} { #<<<
			{*}$cb $name $chan read $bytes
			set bytes
		}

		#>>>
		proc write {cb name chan bytes} { #<<<
			{*}$cb $name $chan write $bytes
			set bytes
		}

		#>>>
		proc drain {cb name chan} { #<<<
			{*}$cb $name $chan drain
			return {}
		}

		#>>>
		proc flush {cb name chan} { #<<<
			{*}$cb $name $chan flush
			return {}
		}

		#>>>
	}

	#>>>
}

# vim: ft=tcl foldmethod=marker foldmarker=<<<,>>> ts=4 shiftwidth=4
