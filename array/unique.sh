# array/unique.sh
#
# Provides array_unique().
#
# Author: konsolebox
# Copyright free, 2010-2012
#


# bool array_unique (avar <input>, [avar <result>])
#
# Removes duplicate entries from array.  If a result variable is
# specified, changes are saved to that variable, or else the input
# variable gets modified instead.  Indices are preserved.
#
# Please don't specify variables that have same names as the local
# variables below.  All of the local variables are prefixed with __ so
# it wont' really be a namespace problem.
#
if [[ BASH_VERSINFO -ge 4 ]]; then
	function array_unique {
		case "$#" in
		1)
			[[ $1 =~ ^[[:alpha:]_]+[[:alnum:]_]*$ ]] || return
			local -A __F=(); local -i __I; local __A
			eval "
				for __I in \"\${!$1[@]}\"; do
					__A=\${$1[__I]}
					[[ -n \${__F[\$__A]} ]] && {
						unset $1\\[__I\\]
						continue
					}
					__F[\$__A]=.
				done
			"
			;;
		2)
			[[ $1 =~ ^[[:alpha:]_]+[[:alnum:]_]*$ && $2 =~ ^[[:alpha:]_]+[[:alnum:]_]*$ ]] || return
			local -A __F=(); local -i __I; local __A
			eval "
				$2=() || return
				for __I in \"\${!$1[@]}\"; do
					__A=\${$1[__I]}
					[[ -n \${__F[\$__A]} ]] && continue
					$2[__I]=\$__A
					__F[\$__A]=.
				done
			"
			;;
#		*)
#			echo "invalid number of arguments."
#			exit 1
#			;;
		esac
	}
else
	# Note: At first I thought that a method like the one presented by the
	#       second version will yield faster result since it doesn't
	#       reallocate the indices everytime a repeating line is removed.
	#       That could have been the case but as tests shows, the first
	#       version yielded faster performance in most cases.  The second
	#       version is only faster when there are -very- many similarities
	#       in many lines.
	#
	#       It appears that the overhead of having manier instructions is
	#       greater than the overhead of recollecting indices.  The second
	#       version could be just faster if its lines can be reduced.  It
	#       can perhaps also be faster if implemented in languages other
	#       than bash.
	#

	if true; then
		function array_unique {
			case "$#" in
			1)
				eval "
					local -a __T=(\"\${!$1[@]}\") || return
					local -i __I=0 __J __C=\${#__T[@]} __D=0
					for (( ; __I < __C; ++__I )); do
						for (( __J = __I + 1; __J < __C; ++__J )); do
							[[ \${$1[__T[__I]]} = \"\${$1[__T[__J]]}\" ]] && {
								unset $1\\[__T\\[__J\\]\\] __T\\[__J\\]
								(( ++__D ))
							}
						done
						[[ __D -gt 0 ]] && {
							__T=(\"\${__T[@]:__I + 1}\")
							(( __C -= __D + __I + 1, __I = -1, __D = 0 ))
						}
					done
					return 0
				"
				;;
			2)
				eval "
					local -a __T=(\"\${!$1[@]}\") || return
					local -i __I=0 __J __C=\${#__T[@]} __D=0
					$2=() || return
					for (( ; __I < __C; ++__I )); do
						for (( __J = __I + 1; __J < __C; ++__J )); do
							[[ \${$1[__T[__I]]} = \"\${$1[__T[__J]]}\" ]] && {
								unset __T\\[__J\\]
								(( ++__D ))
							}
						done
						__J=__T[__I]
						$2[__J]=\${$1[__J]} || return
						[[ __D -gt 0 ]] && {
							__T=(\"\${__T[@]:__I + 1}\")
							(( __C -= __D + __I + 1, __I = -1, __D = 0 ))
						}
					done
					return 0
				"
				;;
#			*)
#				echo "invalid number of arguments."
#				exit 1
#				;;
			esac
			return 1
		}
	else
		function array_unique {
			case "$#" in
			1)
				eval "
					local -i -a __T=(\"\${!$1[@]}\") __U=() || return
					local -i __I=0 __J __C=\${#__T[@]} __P
					for (( ; __I < __C; __I += __U[__I] + 1 )); do
						for (( __P = __I, __J = __I + __U[__I] + 1; __J < __C; __J += __U[__J] + 1 )); do
							[[ \${$1[__T[__I]]} = \"\${$1[__T[__J]]}\" ]] && {
								(( __U[__P] += __U[__J] + 1 ))
								unset $1\\[__T\\[__J\\]\\]
								continue
							}
							(( __P = __J ))
						done
					done
					return 0
				"
				;;
			2)
				eval "
					local -i -a __T=(\"\${!$1[@]}\") __U=() || return
					local -i __I=0 __J __C=\${#__T[@]} __P
					$2=() || return
					for (( ; __I < __C; __I += __U[__I] + 1 )); do
						__J=__T[__I]
						$2[__J]=\${$1[__J]} || return
						for (( __P = __I, __J = __I + __U[__I] + 1; __J < __C; __J += __U[__J] + 1 )); do
							[[ \${$1[\${__T[__I]}]} = \"\${$1[__T[__J]]}\" ]] && {
								(( __U[__P] += __U[__J] + 1 ))
								continue
							}
							(( __P = __J ))
						done
					done
					return 0
				"
				;;
#			*)
#				echo "invalid number of arguments."
#				exit 1
#				;;
			esac
			return 1
		}
	fi
fi
