! =============================================================================
! Código Fortran para simulación de Péndulo Forzado y Amortiguado
! Método: Runge-Kutta de 4to orden
! Autora: [Lisset Salinas]
! Repositorio: [https://github.com/liswizard/proyecto-pendulo-caotico]
! =============================================================================

program pendulo_forzado_amortiguado
    implicit none
    
    ! =========================================================================
    ! PARÁMETROS DE SIMULACIÓN
    ! =========================================================================
    integer, parameter :: n_cases = 3           ! Número de casos a simular
    integer, parameter :: n_steps = 20000       ! Número de pasos temporales
    real(8), parameter :: h = 0.01d0            ! Paso temporal
    real(8), parameter :: t_span(2) = [0.0d0, 200.0d0]  ! Tiempo de simulación
    
    ! Parámetros para cada caso (nu, tau, f)
    real(8) :: params(n_cases, 3)
    character(len=10) :: case_labels(n_cases)
    
    ! Variables de estado del sistema
    real(8) :: t(n_steps)                       ! Vector de tiempos
    real(8) :: theta1(n_steps), omega1(n_steps) ! Estado 1: theta, omega
    real(8) :: theta2(n_steps), omega2(n_steps) ! Estado 2: theta, omega
    real(8) :: delta_theta(n_steps)             ! Diferencia entre trayectorias
    
    ! Condiciones iniciales
    real(8) :: y0_1(2) = [0.0d0, 0.0d0]        ! theta=0, omega=0
    real(8) :: y0_2(2) = [0.0001d0, 0.0d0]     ! Pequeña variación en theta
    
    integer :: i, case_num
    
    ! =========================================================================
    ! CONFIGURACIÓN DE PARÁMETROS PARA CADA CASO
    ! =========================================================================
    case_labels(1) = 'Caso A'
    case_labels(2) = 'Caso B' 
    case_labels(3) = 'Caso C'
    
    ! Caso A: Comportamiento periódico
    params(1,1) = 0.5d0   ! nu (coeficiente de amortiguamiento)
    params(1,2) = 0.90d0  ! tau (amplitud de forzamiento)
    params(1,3) = 1.0d0/(6.0d0*3.141592653589793d0)  ! f (frecuencia)
    
    ! Caso B: Transición
    params(2,1) = 0.5d0   ! nu
    params(2,2) = 1.07d0  ! tau
    params(2,3) = 1.0d0/(6.0d0*3.141592653589793d0)  ! f
    
    ! Caso C: Comportamiento caótico
    params(3,1) = 0.5d0   ! nu
    params(3,2) = 1.15d0  ! tau
    params(3,3) = 1.0d0/(6.0d0*3.141592653589793d0)  ! f
    
    ! =========================================================================
    ! EJECUCIÓN PRINCIPAL
    ! =========================================================================
    print *, '========================================================='
    print *, '    SIMULACIÓN PÉNDULO FORZADO Y AMORTIGUADO'
    print *, '========================================================='
    print *, ''
    
    ! Ejecutar simulación para cada caso
    do case_num = 1, n_cases
        print *, 'Simulando: ', case_labels(case_num)
        print *, 'Parámetros: nu = ', params(case_num,1), &
                         ', tau = ', params(case_num,2), &
                         ', f = ', params(case_num,3)
        
        ! Simulación con condiciones iniciales 1
        call runge_kutta_simulation(y0_1, params(case_num,:), &
                                  t, theta1, omega1, n_steps, h, t_span)
        
        ! Simulación con condiciones iniciales 2 (ligeramente diferentes)
        call runge_kutta_simulation(y0_2, params(case_num,:), &
                                  t, theta2, omega2, n_steps, h, t_span)
        
        ! Calcular diferencia entre trayectorias
        do i = 1, n_steps
            delta_theta(i) = abs(theta1(i) - theta2(i))
        end do
        
        ! Guardar resultados en archivo
        call save_results(case_labels(case_num), t, theta1, omega1, &
                         theta2, omega2, delta_theta, params(case_num,:), n_steps)
        
        ! Análisis del comportamiento (caótico vs periódico)
        call analyze_behavior(case_labels(case_num), delta_theta, n_steps)
        
        print *, '---------------------------------------------------------'
    end do
    
    print *, 'SIMULACIÓN COMPLETADA EXITOSAMENTE'
    print *, 'Resultados guardados en archivos: resultados_Caso[].dat'
    print *, '========================================================='
    
contains

    ! =====================================================================
    ! SUBRUTINA: pendulo_func
    ! Propósito: Define el sistema de ecuaciones del péndulo forzado
    ! =====================================================================
    subroutine pendulo_func(t, y, dydt, params)
        real(8), intent(in) :: t        ! Tiempo actual
        real(8), intent(in) :: y(2)     ! Vector de estado [theta, omega]
        real(8), intent(in) :: params(3)! Parámetros [nu, tau, f]
        real(8), intent(out) :: dydt(2) ! Derivadas [dtheta/dt, domega/dt]
        
        real(8) :: nu, tau, f
        
        nu = params(1)   ! Coeficiente de amortiguamiento
        tau = params(2)  ! Amplitud de forzamiento
        f = params(3)    ! Frecuencia de forzamiento
        
        ! Sistema de ecuaciones:
        ! dtheta/dt = omega
        ! domega/dt = -nu*omega - sin(theta) + tau*sin(2*pi*f*t)
        dydt(1) = y(2)  
        dydt(2) = -nu * y(2) - sin(y(1)) + tau * sin(2.0d0 * 3.141592653589793d0 * f * t)
    end subroutine pendulo_func

    ! =====================================================================
    ! SUBRUTINA: runge_kutta_simulation
    ! Propósito: Implementa el método de Runge-Kutta de 4to orden
    ! =====================================================================
    subroutine runge_kutta_simulation(y0, params, t_out, theta_out, omega_out, &
                                    n_steps, h, t_span)
        real(8), intent(in) :: y0(2)     ! Condiciones iniciales
        real(8), intent(in) :: params(3) ! Parámetros del sistema
        real(8), intent(in) :: h         ! Paso temporal
        real(8), intent(in) :: t_span(2) ! Intervalo de tiempo [t0, tf]
        integer, intent(in) :: n_steps   ! Número de pasos
        real(8), intent(out) :: t_out(n_steps)    ! Tiempos de salida
        real(8), intent(out) :: theta_out(n_steps)! Ángulos de salida
        real(8), intent(out) :: omega_out(n_steps)! Velocidades de salida
        
        real(8) :: y(2)     ! Estado actual [theta, omega]
        real(8) :: k1(2), k2(2), k3(2), k4(2)  ! Coeficientes RK4
        real(8) :: current_t ! Tiempo actual
        integer :: i        ! Contador de pasos
        
        ! Inicializar condiciones
        y = y0
        current_t = t_span(1)
        
        ! Integración temporal
        do i = 1, n_steps
            ! Almacenar estado actual
            t_out(i) = current_t
            theta_out(i) = y(1)
            omega_out(i) = y(2)
            
            ! Avanzar un paso con Runge-Kutta 4
            call rk4_step(current_t, y, h, params)
            current_t = current_t + h
        end do
        
    end subroutine runge_kutta_simulation

    ! =====================================================================
    ! SUBRUTINA: rk4_step
    ! Propósito: Realiza un paso del método Runge-Kutta de 4to orden
    ! =====================================================================
    subroutine rk4_step(t, y, h, params)
        real(8), intent(in) :: t        ! Tiempo actual
        real(8), intent(in) :: h        ! Paso temporal
        real(8), intent(in) :: params(3)! Parámetros del sistema
        real(8), intent(inout) :: y(2)  ! Estado actual (se actualiza)
        
        real(8) :: k1(2), k2(2), k3(2), k4(2)  ! Coeficientes RK4
        real(8) :: y_temp(2)            ! Estado temporal
        
        ! Coeficiente k1
        call pendulo_func(t, y, k1, params)
        
        ! Coeficiente k2
        y_temp = y + (h/2.0d0) * k1
        call pendulo_func(t + h/2.0d0, y_temp, k2, params)
        
        ! Coeficiente k3
        y_temp = y + (h/2.0d0) * k2
        call pendulo_func(t + h/2.0d0, y_temp, k3, params)
        
        ! Coeficiente k4
        y_temp = y + h * k3
        call pendulo_func(t + h, y_temp, k4, params)
        
        ! Actualización del estado
        y = y + (h/6.0d0) * (k1 + 2.0d0*k2 + 2.0d0*k3 + k4)
        
    end subroutine rk4_step

    ! =====================================================================
    ! SUBRUTINA: save_results
    ! Propósito: Guarda los resultados en archivos de texto
    ! =====================================================================
    subroutine save_results(case_label, t, theta1, omega1, theta2, omega2, &
                          delta_theta, params, n_steps)
        character(len=*), intent(in) :: case_label  ! Etiqueta del caso
        real(8), intent(in) :: t(n_steps)           ! Vector de tiempos
        real(8), intent(in) :: theta1(n_steps)      ! Ángulo (condición 1)
        real(8), intent(in) :: omega1(n_steps)      ! Velocidad (condición 1)
        real(8), intent(in) :: theta2(n_steps)      ! Ángulo (condición 2)
        real(8), intent(in) :: omega2(n_steps)      ! Velocidad (condición 2)
        real(8), intent(in) :: delta_theta(n_steps) ! Diferencia entre trayectorias
        real(8), intent(in) :: params(3)            ! Parámetros del caso
        integer, intent(in) :: n_steps              ! Número de puntos
        
        character(len=50) :: filename  ! Nombre del archivo
        integer :: i, unit            ! Contador y unidad de archivo
        
        ! Crear nombre del archivo
        filename = 'resultados_' // trim(case_label) // '.dat'
        
        ! Abrir archivo para escritura
        open(newunit=unit, file=trim(filename), status='replace', action='write')
        
        ! Escribir encabezado informativo
        write(unit, '(A)') '# =========================================='
        write(unit, '(A)') '# Resultados: Péndulo Forzado y Amortiguado'
        write(unit, '(A, A)') '# Caso: ', trim(case_label)
        write(unit, '(A, F6.3)') '# Coeficiente de amortiguamiento (nu): ', params(1)
        write(unit, '(A, F6.3)') '# Amplitud de forzamiento (tau): ', params(2)
        write(unit, '(A, F8.5)') '# Frecuencia de forzamiento (f): ', params(3)
        write(unit, '(A)') '# =========================================='
        write(unit, '(A)') '# Columas: t, theta1, omega1, theta2, omega2, delta_theta'
        
        ! Escribir datos
        do i = 1, n_steps
            write(unit, '(6F15.8)') t(i), theta1(i), omega1(i), &
                                   theta2(i), omega2(i), delta_theta(i)
        end do
        
        close(unit)
        
        print *, 'Resultados guardados en: ', trim(filename)
    end subroutine save_results

    ! =====================================================================
    ! SUBRUTINA: analyze_behavior
    ! Propósito: Analiza el comportamiento (caótico vs periódico)
    ! =====================================================================
    subroutine analyze_behavior(case_label, delta_theta, n_steps)
        character(len=*), intent(in) :: case_label  ! Etiqueta del caso
        real(8), intent(in) :: delta_theta(n_steps) ! Diferencia entre trayectorias
        integer, intent(in) :: n_steps              ! Número de puntos
        
        real(8) :: max_delta    ! Diferencia máxima
        real(8) :: mean_delta   ! Diferencia promedio
        integer :: i           ! Contador
        
        ! Inicializar variables
        max_delta = 0.0d0
        mean_delta = 0.0d0
        
        ! Calcular diferencia máxima y promedio
        do i = 1, n_steps
            if (delta_theta(i) > max_delta) then
                max_delta = delta_theta(i)
            end if
            mean_delta = mean_delta + delta_theta(i)
        end do
        
        mean_delta = mean_delta / real(n_steps, 8)
        
        ! Mostrar análisis
        print *, 'Análisis ', trim(case_label), ':'
        print *, '  Diferencia máxima: ', max_delta
        print *, '  Diferencia promedio: ', mean_delta
        
        ! Clasificar comportamiento
        if (max_delta > 0.1d0) then
            print *, '  Comportamiento: CAÓTICO'
        else
            print *, '  Comportamiento: PERIÓDICO'
        end if
    end subroutine analyze_behavior

end program pendulo_forzado_amortiguado
