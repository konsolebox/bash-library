include array.sh


# ----------------------------------------------------------------------

# array/sort.sh
#
# A portable utility that provides a function that sorts an array of a
# specific type.  The sorted output can be in the form of values or
# indices.
#
# This methods were based from QuickSort (the one described in
# "A Book on C 4th Ed.").
#
# Credits have got to be given to the authors of the book
# "A Book on C 4th Ed." for this great algorithm.  The algorithm was
# originally described by someone and was completely explained in the
# book with an implimentation that's written in C.
#
# I knew C from many sources but most of what I learned came from this
# book and I therefore recommend it to starters for a good start and
# also to experienced programmers for a good reference and new methods
# that they may discover from it.
#
# I hope you enjoy using these functions and/or algorithms.
#
# Author: konsolebox
# Copyright free, 2008-2012

# ----------------------------------------------------------------------


# void array_sort
# (
# 	["from=<array>"],
# 	["type=<string|integer>"],
# 	["to=<array>"],
# 	["as=<values|indices>"],
# 	["--" [ SOURCEVALUES[@] ]]
# )
#
function array_sort {
	[[ $# -eq 0 ]] && return

	local __FROM __TYPE __TO __AS
	local -a __ARRAY
	local -a -i __INDICES

	while [[ $# -gt 0 ]]; do
		case "$1" in
		from=*)
			__FROM=${1#from=}
			;;
		type=*)
			__TYPE=${1#type=}
			;;
		to=*)
			__TO=${1#to=}
			;;
		as=*)
			__AS=${1#as=}
			;;
		--)
			shift
			break
			;;
		#beginsyntaxcheckblock
		*)
			array_sort_error "unknown parameter: $1"
			;;
		#endsyntaxcheckblock
		esac
		shift
	done

	#beginsyntaxcheckblock
	[[ -n $__FROM && $__FROM != [[:alpha:]_]*([[:alpha:][:digit:]_]) ]] && \
		array_sort_error "variable name not valid for the source array: $__FROM"
	[[ -n $__TYPE && $__TYPE != @(string|integer) ]] && \
		array_sort_error "argument is not valid for type: $__TYPE"
	[[ -n $__TO && $__TO != [[:alpha:]_]*([[:alpha:][:digit:]_]) ]] && \
		array_sort_error "variable name not valid for the target array: $__TO"
	[[ -n $__AS && $__AS != @(values|indices) ]] && \
		array_sort_error "argument is not valid for as: $__AS"
	[[ -z $__FROM && $# -eq 0 ]] && \
		array_sort_error "a source should be specified either by 'from=<array>' or '-- CONTENTS[@]'"
	#endsyntaxcheckblock

	if [[ $# -gt 0 ]]; then
		__ARRAY=("$@")
	elif [[ -n $__FROM ]]; then
		array_copy "$__FROM" __ARRAY || \
			array_sort_error "failed to make a temporary working copy of $__FROM."
	fi

	[[ -z $__TYPE ]] && __TYPE=string
	[[ -z $__TO ]] && __TO=__
	[[ -z $__AS ]] && __AS=values

	__INDICES=("${!__ARRAY[@]}")

	if [[ ${#__INDICES[@]} -gt 1 ]]; then
		case "$__TYPE" in
		string)
			array_sort_strings 0 "$(( ${#__INDICES[@]} - 1 ))"
			;;
		integer)
			array_sort_integers 0 "$(( ${#__INDICES[@]} - 1 ))"
			;;
		esac
	fi

	case "$__AS" in
	values)
		local -i I J=0
		array_reset "$__TO"
		eval "for I in \"\${__INDICES[@]}\"; do ${__TO}[J++]=\${__ARRAY[I]}; done"
		;;
	indices)
		eval "$__TO=(\"\${__INDICES[@]}\")"
		;;
	esac
}


# void array_sort_strings (uint LEFT, uint RIGHT)
#
function array_sort_strings {
	[[ $1 -lt $2 ]] || return

	local -i LEFT=$1 RIGHT=$2 PIVOT PARTITION

	if array_sort_strings_findpivot; then
		array_sort_strings_partition
		array_sort_strings "$LEFT" "$(( PARTITION - 1 ))"
		array_sort_strings "$PARTITION" "$RIGHT"
	fi
}


# bool array_sort_strings_findpivot (void)
#
function array_sort_strings_findpivot {
	local -i A B C P MIDDLE

	(( MIDDLE = LEFT + (RIGHT - LEFT) / 2 ))

	(( A = __INDICES[LEFT] ))
	(( B = __INDICES[MIDDLE] ))
	(( C = __INDICES[RIGHT] ))

	[[ ${__ARRAY[A]} > "${__ARRAY[B]}" ]] && (( A = $B, B = $A ))
	[[ ${__ARRAY[A]} > "${__ARRAY[C]}" ]] && (( A = $C, C = $A ))
	[[ ${__ARRAY[B]} > "${__ARRAY[C]}" ]] && (( B = $C, C = $B ))

	if [[ ${__ARRAY[A]} < "${__ARRAY[B]}" ]]; then
		PIVOT=$B
		return 0
	fi

	if [[ ${__ARRAY[B]} < "${__ARRAY[C]}" ]]; then
		PIVOT=$C
		return 0
	fi

	for (( P = LEFT + 1; P < MIDDLE; ++P )); do
		if [[ ${__ARRAY[P]} > "${__ARRAY[A]}" ]]; then
			PIVOT=$P
			return 0
		fi

		if [[ ${__ARRAY[P]} < "${__ARRAY[A]}" ]]; then
			PIVOT=$A
			return 0
		fi
	done

	for (( P = MIDDLE + 1; P < RIGHT; ++P )); do
		if [[ ${__ARRAY[P]} > "${__ARRAY[A]}" ]]; then
			PIVOT=$P
			return 0
		fi

		if [[ ${__ARRAY[P]} < "${__ARRAY[A]}" ]]; then
			PIVOT=$A
			return 0
		fi
	done

	return 1
}


# void array_sort_strings_partition (void)
#
function array_sort_strings_partition {
	local -i L R T
	local P=${__ARRAY[PIVOT]}

	for (( L = LEFT, R = RIGHT; L <= R; )); do
		while [[ ${__ARRAY[__INDICES[L]]} < "$P" ]]; do
			(( ++L ))
		done

		until [[ ${__ARRAY[__INDICES[R]]} < "$P" ]]; do
			(( --R ))
		done

		[[ L -lt R ]] && (( T = __INDICES[L], __INDICES[L] = __INDICES[R], __INDICES[R] = T, ++L, --R ))
	done

	(( PARTITION = L ))
}


# void array_sort_integers (uint LEFT, uint RIGHT)
#
function array_sort_integers {
	[[ $1 -lt $2 ]] || return

	local -i LEFT=$1 RIGHT=$2 PIVOT PARTITION

	if array_sort_integers_findpivot; then
		array_sort_integers_partition
		array_sort_integers "$LEFT" "$(( PARTITION - 1 ))"
		array_sort_integers "$PARTITION" "$RIGHT"
	fi
}


# bool array_sort_integers_findpivot (void)
#
function array_sort_integers_findpivot {
	local -i A B C P MIDDLE

	(( MIDDLE = LEFT + (RIGHT - LEFT) / 2 ))

	(( A = __INDICES[LEFT] ))
	(( B = __INDICES[MIDDLE] ))
	(( C = __INDICES[RIGHT] ))

	[[ __ARRAY[A] -gt __ARRAY[B] ]] && (( A = $B, B = $A ))
	[[ __ARRAY[A] -gt __ARRAY[C] ]] && (( A = $C, C = $A ))
	[[ __ARRAY[B] -gt __ARRAY[C] ]] && (( B = $C, C = $B ))

	if [[ __ARRAY[A] -lt __ARRAY[B] ]]; then
		PIVOT=$B
		return 0
	fi

	if [[ __ARRAY[B] -lt __ARRAY[C] ]]; then
		PIVOT=$C
		return 0
	fi

	for (( P = LEFT + 1; P < MIDDLE; ++P )); do
		if [[ __ARRAY[P] -gt __ARRAY[A] ]]; then
			PIVOT=$P
			return 0
		fi

		if [[ __ARRAY[P] -lt __ARRAY[A] ]]; then
			PIVOT=$A
			return 0
		fi
	done

	for (( P = MIDDLE + 1; P < RIGHT; ++P )); do
		if [[ __ARRAY[P] -gt __ARRAY[A] ]]; then
			PIVOT=$P
			return 0
		fi

		if [[ __ARRAY[P] -lt __ARRAY[A] ]]; then
			PIVOT=$A
			return 0
		fi
	done

	return 1
}


# void array_sort_integers_partition (void)
#
function array_sort_integers_partition {
	local -i L R T P

	for (( L = LEFT, R = RIGHT, P = __ARRAY[PIVOT]; L <= R; )); do
		for (( ; __ARRAY[__INDICES[L]] < P; ++L )); do
			continue
		done

		for (( ; __ARRAY[__INDICES[R]] >= P; --R )); do
			continue
		done

		[[ L -lt R ]] && (( T = __INDICES[L], __INDICES[L] = __INDICES[R], __INDICES[R] = T, ++L, --R ))
	done

	(( PARTITION = L ))
}


# void array_sort_error (string <message>)
#
function array_sort_error {
	echo "array_sort: $1"
	exit 1
}


# ----------------------------------------------------------------------

# Footnotes:
#
# * In some versions of bash, conditional statements does not properly
#   parse the second string operand so sometimes this form doesn't work:
#
#   [[ $STRINGVAR1 < $STRINGVAR2 ]]
#
#   So to make it work, we have no choice but put it around quotes:
#
#   [[ $STRINGVAR1 < "$STRINGVAR2" ]]
#
# * In some versions of bash, a segmentation fault occurs when
#   assignment statements where sources are arrays are compounded.
#
#   (( A = __A0[INDEX1], B = __A0[INDEX2] ))

# ----------------------------------------------------------------------
