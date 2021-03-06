! Burn a single cell and output time-series integration data.

program burn_cell

  use bl_constants_module
  use bl_types
  use probin_module, only: run_prefix, small_temp, small_dens
  use runtime_init_module
  use extern_probin_module
  use burn_type_module
  use actual_burner_module
  use microphysics_module
  use eos_type_module, only : eos_get_small_temp, eos_get_small_dens
  use eos_module
  use network
  use build_info_module

  implicit none

  type (burn_t)       :: burn_state_in, burn_state_out

  real (kind=dp_t)    :: tmax, energy, dt
  integer             :: ntimes, i

  character (len=256) :: out_name
  character (len=6)   :: out_num

  ! runtime
  call runtime_init(.true.)
  
  ! microphysics
  call microphysics_init(small_temp=small_temp, small_dens=small_dens)
  call eos_get_small_temp(small_temp)
  print *, "small_temp = ", small_temp
  call eos_get_small_dens(small_dens)
  print *, "small_dens = ", small_dens

  ! Fill burn state input
  write(*,*) 'Maximum Time (s): '
  read(*,*) tmax
  write(*,*) 'Number of time subdivisions: '
  read(*,*) ntimes
  write(*,*) 'State Density (g/cm^3): '
  read(*,*) burn_state_in%rho
  write(*,*) 'State Temperature (K): '
  read(*,*) burn_state_in%T
  do i = 1, nspec
     write(*,*) 'Mass Fraction (', spec_names(i), '): '
     read(*,*) burn_state_in%xn(i)
  end do

  ! normalize -- just in case
  !call normalize_abundances_burn(burn_state_in)

  ! Initialize initial energy to zero
  burn_state_in % e = ZERO
  burn_state_out % e = ZERO
  energy = ZERO

  ! output initial burn type data
  write(out_num,'(I6.6)') 0
  out_name = trim(run_prefix) // out_num
  burn_state_in % time = ZERO
  call write_burn_t(out_name, burn_state_in)
  
  dt = tmax/ntimes
  
  do i = 1, ntimes
     ! Do burn
     call actual_burner(burn_state_in, burn_state_out, dt, ZERO)
     energy = energy + burn_state_out % e
     burn_state_in = burn_state_out
     burn_state_in % e = ZERO
     write(*,*) 'Completed burn to: ', dt*i, ' seconds'
     
     ! output burn type data
     write(out_num,'(I6.6)') i
     out_name = trim(run_prefix) // out_num
     call write_burn_t(out_name, burn_state_out)
  end do

  call microphysics_finalize()

end program burn_cell

subroutine write_burn_t(fname, burnt)
  use network
  use burn_type_module

  implicit none
  
  ! Writes contents of burn_t type burnt to file named fname
  character(len=256), intent(in) :: fname
  type(burn_t), intent(in) :: burnt
  integer, parameter :: burn_t_unit = 10
  character(len=20), parameter :: DPFMT = '(E30.16E5)'
  character(len=20) :: VDPFMT = ''
  
  integer :: i, j

  open(unit=burn_t_unit, file=fname, action='WRITE')
  write(unit=burn_t_unit, fmt=*) '! Burn Type Data'

  write(unit=burn_t_unit, fmt=*) 'nspec:'
  write(unit=burn_t_unit, fmt=*) nspec
  
  write(unit=burn_t_unit, fmt=*) 'neqs:'
  write(unit=burn_t_unit, fmt=*) neqs

  write(unit=burn_t_unit, fmt=*) 'short_spec_names:'
  do i = 1, nspec
     write(unit=burn_t_unit, fmt=*) short_spec_names(i)
  end do
  
  write(unit=burn_t_unit, fmt=*) 'rho:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % rho

  write(unit=burn_t_unit, fmt=*) 'T:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % T

  write(unit=burn_t_unit, fmt=*) 'e:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % e

  write(VDPFMT, '("(", I0, "E30.16E5", ")")') nspec
  write(unit=burn_t_unit, fmt=*) 'xn:'
  write(unit=burn_t_unit, fmt=VDPFMT) (burnt % xn(i), i = 1, nspec)

  write(unit=burn_t_unit, fmt=*) 'cv:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % cv

  write(unit=burn_t_unit, fmt=*) 'cp:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % cp

  write(unit=burn_t_unit, fmt=*) 'y_e:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % y_e

  write(unit=burn_t_unit, fmt=*) 'eta:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % eta

  write(unit=burn_t_unit, fmt=*) 'cs:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % cs

  write(unit=burn_t_unit, fmt=*) 'dx:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % dx

  write(unit=burn_t_unit, fmt=*) 'abar:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % abar

  write(unit=burn_t_unit, fmt=*) 'zbar:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % zbar

  write(unit=burn_t_unit, fmt=*) 'T_old:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % T_old

  write(unit=burn_t_unit, fmt=*) 'dcvdT:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % dcvdT

  write(unit=burn_t_unit, fmt=*) 'dcpdT:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % dcpdT

  write(VDPFMT, '("(", I0, "E30.16E5", ")")') neqs
  write(unit=burn_t_unit, fmt=*) 'ydot:'
  write(unit=burn_t_unit, fmt=VDPFMT) (burnt % ydot(i), i = 1, neqs)

  write(unit=burn_t_unit, fmt=*) 'jac:'
  do i = 1, neqs
     write(unit=burn_t_unit, fmt=VDPFMT) (burnt % jac(i,j), j = 1, neqs)
  end do

  write(unit=burn_t_unit, fmt=*) 'self_heat:'
  write(unit=burn_t_unit, fmt=*) burnt % self_heat

  write(unit=burn_t_unit, fmt=*) 'i:'
  write(unit=burn_t_unit, fmt=*) burnt % i
  
  write(unit=burn_t_unit, fmt=*) 'j:'
  write(unit=burn_t_unit, fmt=*) burnt % j

  write(unit=burn_t_unit, fmt=*) 'k:'
  write(unit=burn_t_unit, fmt=*) burnt % k

  write(unit=burn_t_unit, fmt=*) 'n_rhs:'
  write(unit=burn_t_unit, fmt=*) burnt % n_rhs

  write(unit=burn_t_unit, fmt=*) 'n_jac:'
  write(unit=burn_t_unit, fmt=*) burnt % n_jac

  write(unit=burn_t_unit, fmt=*) 'time:'
  write(unit=burn_t_unit, fmt=DPFMT) burnt % time
  
  close(unit=burn_t_unit)
end subroutine write_burn_t
