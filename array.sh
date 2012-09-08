# ----------------------------------------------------------------------

# array.sh
#
# Provides functions for common manipulation of indexed arrays in Bash.
#
# Functions currently included are:
#
# array_push(), array_push_r(), array_push_f()
# array_pop(), array_pop_r(), array_pop_f()
# array_shift(), array_shift_r(), array_shift_f()
# array_unshift(), array_unshift_r(), array_unshift_f()
# array_get(), array_get_all(), array_get_indices(),
# array_get_first(), array_get_first_index(),
# array_get_last(), array_get_last_index(),
# array_set(), array_reset(),
# array_copy(), array_move(),
# array_has_value(), array_has_values(),
# array_has_index(), array_has_indices()
# array_isempty(), array_isnotempty(),
# array_size(), array_length()
#
# This script requires bash versions 3.0 or newer.
#
# Author: konsolebox
# Copyright Free / Public Domain
# June 30, 2010
#
# Last Updated: 2012/09/08
# Version: 0.2.2.2

# ----------------------------------------------------------------------


if ! [[ BASH_VERSINFO -ge 3 ]]; then
	echo "array.sh: This script requires bash version 3.0 or newer."
	exit 1
fi


# void array_push (avar <array>, mixed <element_value>, ...)
#
# Pushes or appends one or more elements to an array.
#
if [[ BASH_VERSINFO -ge 4 || (BASH_VERSINFO -eq 3 && BASH_VERSINFO[1] -ge 1) ]]; then
	function array_push {
		eval "$1+=(\"\${@:2}\")"
	}
else
	function array_push {
		eval "
			local -a __T=(\"\${!$1[@]}\")
			local __A __I=\${__T[@]: -1}
			shift
			for __A; do
				$1[++__I]=\$__A
			done
		"
	}
fi


# void array_push_r (avar <array>, mixed <element_value>, ...)
#
# Same as array_push() but resets indices in continuous order from 0.
#
function array_push_r {
	eval "$1=(\"\${$1[@]}\" \"\${@:2}\")"
}


# void array_push_f (avar <array>, mixed <element_value>, ...)
#
# Uses fastest method regardless of how indices are affected.
#
if [[ BASH_VERSINFO -ge 4 || (BASH_VERSINFO -eq 3 && BASH_VERSINFO[1] -ge 1) ]]; then
	function array_push_f {
		eval "$1+=(\"\${@:2}\")"
	}
else
	function array_push_f {
		eval "$1=(\"\${$1[@]}\" \"\${@:2}\")"
	}
fi


# bool array_pop (avar <src>, [var <dest>])
#
# Pops an element from an array.  If <dest> is specified, the value will
# be set to it.  If a value can be popped (array is not empty), this
# function will return a true status code.
#
function array_pop {
	eval "
		[[ \"\${#$1[@]}\" -gt 0 ]] || return
		${2:+"$2=\${$1[@]: -1}"}
		local -a __T=(\"\${!$1[@]}\")
		unset \"$1[\${__T[@]: -1}]\"
	"
}


# bool array_pop_r (avar <src>, [var <dest>])
#
# Same as array_pop() but resets indices in continuous order from 0.
#
function array_pop_r {
	eval "
		[[ \"\${#$1[@]}\" -gt 0 ]] || return
		${2:+"$2=\${$1[@]: -1}"}
		$1=(\"\${$1[@]:0:\${#$1[@]} - 1}\")
	"
}


# bool array_pop_f (avar <src>, [var <dest>])
#
# Same as array_pop() but uses fastest method regardless of how
# indices are affected.
#
function array_pop_f {
	eval "
		[[ \"\${#$1[@]}\" -gt 0 ]] || return
		${2:+"$2=\${$1[@]: -1}"}
		$1=(\"\${$1[@]:0:\${#$1[@]} - 1}\")
	"
}


# bool array_shift (avar <array>, [var <dest>])
#
# Shifts or removes the first element in an array.  If a destination
# variable is specified, the value of the first element will be
# copied to there first.
#
# After removing the first element, the index of the second element
# will move to 0 and all remaining elements will follow at the same
# number of steps that the new first element (previously second)
# has decremented.
#
function array_shift {
	eval "
		case \"\${#$1[@]}\" in
		0)
			return 1
			;;
		1)
			${2:+"$2=\${$1[@]:0:1}"}
			$1=()
			;;
		*)
			${2:+"$2=\${$1[@]:0:1}"}
			local -a __T=(\"\${!$1[@]}\")
			unset $1\\[__T\\]
			local -i __I __D=__T[1]
			for __I in \"\${__T[@]:1}\"; do
				$1[__I - __D]=\${$1[__I]}
				unset $1\\[__I\\]
			done
			;;
		esac
	"
}


# bool array_shift_r (avar <src>, [var <dest>])
#
# Same as array_shift() but resets indices in continuous order from 0.
#
function array_shift_r {
	eval "
		case \"\${#$1[@]}\" in
		0)
			return 1
			;;
		1)
			${2:+"$2=\${$1[@]:0:1}"}
			$1=()
			;;
		*)
			${2:+"$2=\${$1[@]:0:1}"}
			local -a __T=(\"\${!$1[@]}\")
			$1=(\"\${$1[@]:\${__T[1]}}\")
			;;
		esac
	"
}


# bool array_shift_f (avar <src>, [var <dest>])
#
# Same as array_shift() but uses fastest method regardless of
# how indices are affected.
#
function array_shift_f {
	eval "
		case \"\${#$1[@]}\" in
		0)
			return 1
			;;
		1)
			${2:+"$2=\${$1[@]:0:1}"}
			$1=()
			;;
		*)
			${2:+"$2=\${$1[@]:0:1}"}
			local -a __T=(\"\${!$1[@]}\")
			$1=(\"\${$1[@]:\${__T[1]}}\")
			;;
		esac
	"
}


# void array_unshift (avar <array>, mixed <element_value>, ...)
#
# Inserts new elements at the beginning of an array.  The elements are
# added and placed in original order.
#
# e.g. current ("A" "B") + new ("C" "D") = ("C" "D" "A" "B")
#
# All indices of the array's current elements will move 1 step for
# each new element that will be added.
#
function array_unshift {
	local -i __I __J
	eval "
		shift
		local -a __T=(\"\${!$1[@]}\")
		for (( __I = \${#__T[@]}; __I--; )); do
			__J=__T[__I]
			$1[__J + \$#]=\${$1[__J]}
			unset $1\\[__J\\]
		done
		for (( __I = \$#; __I; __I-- )); do
			$1[__I - 1]=\${!__I}
		done
	"
}


# void array_unshift_r (avar <array>, mixed <element_value>, ...)
#
# Same as array_unshift() but resets indices in continuous order from 0.
#
function array_unshift_r {
	eval "$1=(\"\${@:2}\" \"\${$1[@]}\")"
}


# void array_unshift_f (avar <array>, mixed <element_value>, ...)
#
# Same as array_unshift_f() but uses fastest method regardless of
# how indices are affected.
#
function array_unshift_f {
	eval "$1=(\"\${@:2}\" \"\${$1[@]}\")"
}


# void array_get (avar <src>, var <dest>, uint <index>)
#
# Gets the value of an element in an array.
#
# Note: Determining if an element exists is very expensive.  We can use
# [[ -z ... ]] but that still won't tell if an element is just a null
# string or really a non-existing one.  There may be a way to do this
# by modifying shell options but I don't think that it's a good idea
# to change shell options or depend on them.
#
function array_get {
	eval "$2=\${$1[$3]}"
}


# bool array_get_all (avar <src>, avar <dest>)
#
# Gets all the elements of an array.  Function will fail and return
# false if source array is empty.
#
# Also see array_copy().
#
function array_get_all {
	eval "[[ \"\${#$1[@]}\" -gt 0 ]] && $2=(\"\${$1[@]}\")"
}


# bool array_get_indices (avar <src>, avar <dest>)
#
# Gets the indices of an array.
#
# The function fails and returns false if source array is empty.
#
function array_get_indices {
	eval "[[ \"\${#$1[@]}\" -gt 0 ]] && $2=(\"\${!$1[@]}\")"
}


# bool array_get_first (avar <src>, var <dest>)
#
# Gets the value from the first element of an array.
#
# The function fails and returns false if source array is empty.
#
function array_get_first {
	eval "[[ \"\${#$1[@]}\" -gt 0 ]] && $2=\${$1[@]:0:1}"
}


# bool array_get_first_index (avar <src>, var <dest>)
#
# Gets the index of the first element.
#
# The function fails and returns false if source array is empty.
#
function array_get_first_index {
	eval "[[ \"\${#$1[@]}\" -gt 0 ]] && local -a __T=(\"\${!$1[@]}\") && $2=\${__T[@]:0:1}"
}


# bool array_get_last (avar <src>, var <dest>)
#
# Gets the value from the last element of an array.
#
# The function fails and returns false if source array is empty.
#
function array_get_last {
	eval "[[ \"\${#$1[@]}\" -gt 0 ]] && $2=\${$1[@]: -1}"
}


# bool array_get_last_index (avar <src>, var <dest>)
#
# Gets the index of the first element.
#
# The function fails and returns false if source array is empty.
#
function array_get_last_index {
	eval "[[ \"\${#$1[@]}\" -gt 0 ]] && local -a __T=(\"\${!$1[@]}\") && $2=\${__T[@]: -1}"
}


# void array_set (avar <array>, int <index>, mixed <element_value>)
#
# Sets an element to an array.
#
function array_set {
	eval "$1[$2]=\$3"
}


# void array_reset (avar <array>, [mixed <element_value>, ...])
#
# Clears an array or resets it to optional elements.
#
function array_reset {
	eval "$1=(\"\${@:2}\")"
}


# bool array_copy (avar <src>, avar <dest>)
#
# Copies a whole array including index (key) structure.
#
# For a faster method that does not copy key structure, see
# array_get_all().
#
# This function will return true status code even if the source array
# is empty.  It may only return false if other problem occurs like for
# example if source or destination array is not an indexed array
# variable or if the two array variables are not compatible.
# On the other hand, array_get_all() returns false if source array is
# empty.
#
function array_copy {
	local -i __I
	eval "$2=() && for __I in \${!$1[@]}; do $2[__I]=\${$1[__I]}; done"

	# I hope AVAR=() does not reset variable's attributes.  I've been
	# wondering if I should use 'unset AVAR\[*\]' instead.  The latter
	# version probably is a bit slower though since it's a builtin call.
}


# bool array_move (avar <src>, avar <dest>)
#
# Copies a whole array to a new array (includes index / key structure).
# The elements of the source array are cleared afterwards.
#
function array_move {
	eval "$2=() && for __I in \${!$1[@]}; do $2[__I]=\${$1[__I]}; done && $1=()"
}


# bool array_has_value (avar <array>, mixed <value1>, [<mixed value2>, ...])
#
# Returns true status code if either of the values exists in array.
#
function array_has_value {
	[[ $# -ge 2 ]] || return
	local __A __B
	eval "
		shift
		for __A; do
			for __B in \"\${$1[@]}\"; do
				[[ \$__B = \"\$__A\" ]] && return 0
			done
		done
	"
	return 1
}


# bool array_has_values (avar <array>, mixed <value1>, [<mixed value2>, ...])
#
# Returns true status code if all of the values exist in array.
#
function array_has_values {
	[[ $# -ge 2 ]] || return
	local __A __B
	eval "
		shift
		for __A; do
			for __B in \"\${$1[@]}\"; do
				[[ \$__B = \"\$__A\" ]] && continue 2
			done
			return 1
		done
		return 0
	"
}


# bool array_has_index (avar <array>, int <index1>, [<int index2>, ...])
#
# Returns true status code if array contains an element with an index
# that's one of the indices specifed.
#
function array_has_index {
	[[ $# -ge 2 ]] || return
	local __A __B
	eval "
		shift
		for __A; do
			for __B in \"\${!$1[@]}\"; do
				[[ \$__B = \"\$__A\" ]] && return 0
			done
		done
	"
	return 1
}


# bool array_has_indices (avar <array>, int <index1>, [<int index2>, ...])
#
# Returns true status code if array contains some elements with indices
# that are all specified in the arguments.
#
function array_has_indices {
	[[ $# -ge 2 ]] || return
	local __A __B
	eval "
		shift
		for __A; do
			for __B in \"\${!$1[@]}\"; do
				[[ \$__B = \"\$__A\" ]] && continue 2
			done
			return 1
		done
		return 0
	"
}


# bool array_isempty (avar <array>)
#
# Returns true if array is empty.
#
function array_isempty {
	eval "[[ \${#$1[@]} -eq 0 ]]"
}


# bool array_isnotempty (avar <array>)
#
# Returns true if array is not empty.
#
function array_isnotempty {
	eval "[[ \${#$1[@]} -gt 0 ]]"
}


# bool array_size (avar <array>, int var <i>)
#
# Returns the total number of elements in an array.
#
function array_size {
	eval "$2=\${#$1[@]}"
}


# bool array_length (avar <array>, int var <i>)
#
# Returns the length of an array (total number of place-able elements
# from 0 to last index; or <last index> + 1).  This function is also
# useful for knowing the next index if a new element is to be appended.
#
function array_length {
	eval "[[ \"\${#$1[@]}\" -gt 0 ]] && local -a __T=(\"\${!$1[@]}\") && (( $2 = \${__T[@]: -1} + 1 ))"
}
