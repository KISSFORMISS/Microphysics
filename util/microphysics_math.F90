module microphysics_math_module

  implicit none

  public

  ! We hard-code this value to avoid issues with automatic
  ! array allocation on the GPUs. At present the largest 
  ! array size that we use has 30 entries (aprox13/19/21).
  ! If you create a new network that requires more entries,
  ! increase the size of this parameter (or maybe we can make 
  ! it network-dependent).

  integer, parameter :: max_esum_size = 30

contains

  ! Implementation of the exact summation routine from:
  ! https://code.activestate.com/recipes/393090/

  ! This function computes the sum of an array of
  ! double precision numbers with a result that is
  ! exact to the precision of the arithmetic.
  ! It does this by keeping a running array of
  ! partial sums, where each individual sum is split
  ! between the result and the associated roundoff error,
  ! such that all of the components of the partial
  ! sums array are exactly correct and in increasing
  ! order so that the final summation is also exact.
  ! The idea comes from the paper by Andrew Shewchuk,
  ! "Adaptive Precision Floating-Point Arithmetic and
  ! Fast Robust Geometric Predicates," in Discrete
  ! & Computational Geometry (1997), 18, 305.
  ! http://www.cs.berkeley.edu/~jrs/papers/robustr.pdf

  ! This routine should give the same results
  ! (up to the machine epsilon in double precision)
  ! as a summation done at higher precision.
  ! It is therefore a useful alternative to working
  ! in, say, quad precision arithmetic.

  ! The sum is over the first n components of the
  ! input array, so array must have at least that
  ! many components.

  function esum(array,n)

    !$acc routine seq

    use bl_error_module, only: bl_error
    use bl_types, only: dp_t

    implicit none

    real(dp_t), intent(in) :: array(:)
    integer, intent(in) :: n

    real(dp_t) :: esum

    integer :: i, j, k, km

    ! Note that for performance reasons we are not
    ! initializing the unused values in this array.

    real(dp_t) :: partials(0:max_esum_size-1)

    real(dp_t) :: x, y, z, hi, lo

    ! j keeps track of how many entries in partials are actually used.
    ! The algorithm we model this off of, written in Python, simply
    ! deletes array entries at the end of every outer loop iteration.
    ! The Fortran equivalent to this might be to just zero them out,
    ! but this results in a huge performance hit given how often
    ! this routine is called during in a burn. So we opt instead to
    ! just track how many of the values are meaningful, which j does
    ! automatically, and ignore any data in the remaining slots.

    j = 0

    ! The first partial is just the first term.

    partials(j) = array(1)

    do i = 2, n

       km = j

       j = 0

       x = array(i)

       do k = 0, km

          y = partials(k)

          if (abs(x) < abs(y)) then

             ! Swap x, y

             z = y
             y = x
             x = z

          endif

          hi = x + y
          lo = y - (hi - x)

          if (lo .ne. 0.0_dp_t) then

             partials(j) = lo
             j = j + 1

          endif

          x = hi

       enddo

       partials(j) = x

    enddo

#ifndef ACC
    if (j > n - 1) then
       call bl_error("Error: too many partials created in esum.")
    endif
#endif

    esum = sum(partials(0:j))

  end function esum

end module microphysics_math_module
