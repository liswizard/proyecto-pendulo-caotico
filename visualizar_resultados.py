#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Visualizador de Resultados - Péndulo Forzado y Amortiguado
Autora: [Lisset Salinas]
Repositorio: [https://github.com/liswizard/proyecto-pendulo-caotico]

Este script carga los resultados generados por el código Fortran
y genera visualizaciones para analizar el comportamiento del sistema.
"""

import numpy as np
import matplotlib.pyplot as plt
import glob
import os

def cargar_datos(archivo):
    """
    Carga datos desde archivo generado por Fortran
    
    Parameters:
    -----------
    archivo : str
        Ruta del archivo .dat a cargar
        
    Returns:
    --------
    dict
        Diccionario con los datos cargados
    """
    try:
        datos = np.loadtxt(archivo, comments='#')
        return {
            't': datos[:, 0],           # Tiempo
            'theta1': datos[:, 1],      # Ángulo (condición inicial 1)
            'omega1': datos[:, 2],      # Velocidad angular (condición inicial 1)
            'theta2': datos[:, 3],      # Ángulo (condición inicial 2)  
            'omega2': datos[:, 4],      # Velocidad angular (condición inicial 2)
            'delta': datos[:, 5]        # Diferencia entre trayectorias
        }
    except Exception as e:
        print(f"Error cargando {archivo}: {e}")
        return None

def main():
    """
    Función principal del visualizador
    """
    print("=" * 60)
    print("    VISUALIZADOR - PÉNDULO FORZADO Y AMORTIGUADO")
    print("=" * 60)
    
    # =========================================================================
    # CONFIGURACIÓN DE PARÁMETROS DE VISUALIZACIÓN
    # =========================================================================
    
    # Paleta de colores en tonalidades azul-verde y ocre
    colores = {
        'Caso A': '#2E86AB',    # Azul profundo verdoso
        'Caso B': '#48A9A6',    # Verde azulado suave
        'Caso C': '#A5B452',    # Verde amarillento/ocre suave
    }
    
    # Configuración de estilo para gráficas profesionales
    plt.style.use('default')
    plt.rcParams['font.family'] = 'serif'
    plt.rcParams['font.size'] = 10
    
    # =========================================================================
    # CARGA DE DATOS
    # =========================================================================
    
    # Buscar archivos de resultados
    archivos = glob.glob('resultados_*.dat')
    print(f"\nArchivos encontrados: {len(archivos)}")
    
    if not archivos:
        print("ERROR: No se encontraron archivos resultados_*.dat")
        print("Ejecuta primero el programa Fortran:")
        print("  gfortran -o pendulo pendulo_forzado.f90")
        print("  ./pendulo")
        return
    
    # Mostrar archivos encontrados
    for archivo in archivos:
        print(f"  ✓ {archivo}")
    
    # Cargar datos de todos los archivos
    datos = {}
    for archivo in archivos:
        nombre = archivo.replace('resultados_', '').replace('.dat', '')
        data_cargada = cargar_datos(archivo)
        if data_cargada is not None:
            datos[nombre] = data_cargada
            print(f"Cargado: {nombre} - {len(data_cargada['t'])} puntos")
    
    if not datos:
        print("No se pudieron cargar datos válidos.")
        return
    
    # =========================================================================
    # CREACIÓN DE GRÁFICAS
    # =========================================================================
    
    # Crear figura con 6 subgráficas (2 filas × 3 columnas)
    fig, axs = plt.subplots(2, 3, figsize=(16, 10))
    
    # Configurar fondo blanco para mejor contraste
    fig.patch.set_facecolor('white')
    
    # =========================================================================
    # GRÁFICAS PARA CADA CASO
    # =========================================================================
    
    for nombre, data in datos.items():
        color = colores.get(nombre, '#666666')
        
        # 1. ÁNGULO VS TIEMPO (Gráfica superior izquierda)
        axs[0, 0].plot(data['t'], data['theta1'], 
                      color=color, linewidth=1.8, 
                      label=nombre, alpha=0.9)
        
        # 2. ESPACIO FASE (Gráfica superior central)
        axs[0, 1].plot(data['theta1'], data['omega1'], 
                      color=color, linewidth=1.2, 
                      label=nombre, alpha=0.8)
        
        # 3. DIFERENCIA ENTRE TRAYECTORIAS (Gráfica superior derecha)
        axs[0, 2].plot(data['t'], data['delta'], 
                      color=color, linewidth=1.8, 
                      label=nombre, alpha=0.9)
        
        # 4. ZOOM TEMPORAL - Primeros 10 segundos (Gráfica inferior izquierda)
        idx_zoom = int(10 / 0.01)  # 10 segundos con paso h=0.01
        idx_zoom = min(idx_zoom, len(data['t']))
        axs[1, 0].plot(data['t'][:idx_zoom], data['theta1'][:idx_zoom], 
                      color=color, linewidth=2.0, 
                      label=nombre)
        
        # 5. ESPACIO FASE MÓDULO 2π (Gráfica inferior central)
        theta_mod = data['theta1'] % (2 * np.pi)
        axs[1, 1].scatter(theta_mod, data['omega1'], 
                         color=color, s=0.8, alpha=0.6, 
                         label=nombre)
        
        # 6. DIFERENCIA EN ESCALA LOGARÍTMICA (Gráfica inferior derecha)
        axs[1, 2].semilogy(data['t'], data['delta'], 
                          color=color, linewidth=1.8, 
                          label=nombre)
    
    # =========================================================================
    # CONFIGURACIÓN DE GRÁFICAS - FILA SUPERIOR
    # =========================================================================
    
    titulos_fila_superior = [
        'Ángulo vs Tiempo',
        'Espacio Fase', 
        'Diferencia entre Trayectorias'
    ]
    
    for j, titulo in enumerate(titulos_fila_superior):
        axs[0, j].set_title(titulo, fontweight='bold', 
                           color='#2C5530', fontsize=12)
        axs[0, j].set_facecolor('#F8F9FA')
        axs[0, j].grid(True, alpha=0.4, color='#D1D5DB')
        axs[0, j].legend()
    
    # =========================================================================
    # CONFIGURACIÓN DE GRÁFICAS - FILA INFERIOR
    # =========================================================================
    
    titulos_fila_inferior = [
        'Ángulo vs Tiempo (Zoom 10s)',
        'Espacio Fase (módulo 2π)', 
        'Diferencia (Escala Logarítmica)'
    ]
    
    for j, titulo in enumerate(titulos_fila_inferior):
        axs[1, j].set_title(titulo, fontweight='bold', 
                           color='#2C5530', fontsize=12)
        axs[1, j].set_facecolor('#F8F9FA')
        axs[1, j].grid(True, alpha=0.4, color='#D1D5DB')
        axs[1, j].legend()
    
    # =========================================================================
    # CONFIGURACIÓN DE ETIQUETAS DE EJES
    # =========================================================================
    
    # Etiquetas eje Y - Fila superior
    axs[0, 0].set_ylabel('θ (rad)', color='#2C5530')
    axs[0, 1].set_ylabel('ω (rad/s)', color='#2C5530')
    axs[0, 2].set_ylabel('Δθ (rad)', color='#2C5530')
    
    # Etiquetas eje Y - Fila inferior
    axs[1, 0].set_ylabel('θ (rad)', color='#2C5530')
    axs[1, 1].set_ylabel('ω (rad/s)', color='#2C5530')
    axs[1, 2].set_ylabel('log(Δθ)', color='#2C5530')
    
    # Etiquetas eje X - Fila superior
    axs[0, 0].set_xlabel('Tiempo (s)', color='#2C5530')
    axs[0, 1].set_xlabel('Ángulo θ (rad)', color='#2C5530')
    axs[0, 2].set_xlabel('Tiempo (s)', color='#2C5530')
    
    # Etiquetas eje X - Fila inferior
    for j in range(3):
        axs[1, j].set_xlabel('Tiempo (s)', color='#2C5530')
    axs[1, 1].set_xlabel('θ mod 2π (rad)', color='#2C5530')
    
    # =========================================================================
    # AJUSTE FINAL Y GUARDADO
    # =========================================================================
    
    # Ajustar layout para evitar superposiciones
    plt.tight_layout()
    
    # Guardar gráfica en alta calidad
    nombre_archivo_salida = 'analisis_pendulo_completo.png'
    plt.savefig(nombre_archivo_salida, dpi=300, bbox_inches='tight', 
                facecolor='white', edgecolor='none')
    
    print(f"\nGráfica guardada como: '{nombre_archivo_salida}'")
    
    # =========================================================================
    # ANÁLISIS DE RESULTADOS
    # =========================================================================
    
    print("\n" + "=" * 50)
    print("ANÁLISIS DE COMPORTAMIENTO")
    print("=" * 50)
    
    for nombre, data in datos.items():
        max_diff = np.max(data['delta'])
        avg_diff = np.mean(data['delta'])
        
        # Clasificación del comportamiento
        if max_diff > 0.5:
            comportamiento = "CAÓTICO"
        else:
            comportamiento = "PERIÓDICO"
        
        print(f"\n{nombre}:")
        print(f"  • Diferencia máxima (Δθ_max): {max_diff:.6f} rad")
        print(f"  • Diferencia promedio: {avg_diff:.6f} rad")
        print(f"  • Comportamiento: {comportamiento}")
    
    # =========================================================================
    # INFORMACIÓN ADICIONAL
    # =========================================================================
    
    print("\n" + "=" * 50)
    print("INFORMACIÓN ADICIONAL")
    print("=" * 50)
    print("Paleta de colores utilizada:")
    print("  • Caso A: Azul profundo verdoso (#2E86AB)")
    print("  • Caso B: Verde azulado suave (#48A9A6)") 
    print("  • Caso C: Verde amarillento/ocre (#A5B452)")
    
    print("\nInterpretación:")
    print("  • Sistemas PERIÓDICOS: Δθ se mantiene pequeña y acotada")
    print("  • Sistemas CAÓTICOS: Δθ crece exponencialmente en el tiempo")
    print("  • Umbral de clasificación: Δθ_max > 0.5 rad")
    
    # =========================================================================
    # MOSTRAR GRÁFICAS
    # =========================================================================
    
    print("\nMostrando gráficas...")
    plt.show()

if __name__ == "__main__":
    main()
