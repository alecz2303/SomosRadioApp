# Somos Radio App

Prototipo Android en Flutter para Somos Radio Chiapas.

## Objetivo

Crear una aplicación móvil demostrativa para **Somos Radio 89.1 FM (Tuxtla Gutiérrez)** y **Somos Radio 102.9 FM (San Cristóbal de las Casas)**, consumiendo la infraestructura existente de `radio-api` en lugar de hardcodear las estaciones en la app.

> Concepto demostrativo · Propuesta no oficial

## Arquitectura inicial

- Flutter / Android
- API existente: `alecz2303/radio-api`
- Station esperada: `somos-radio`
- Canales obtenidos dinámicamente desde la API
- Reproductor preparado para evolucionar a audio en segundo plano, controles en notificación y widget Android

## Alcance inicial

1. Base Flutter y tema visual Somos Radio
2. Cliente HTTP y modelos de Station/Channel
3. Home con las dos señales
4. Reproductor y mini reproductor persistente
5. Programación, noticias, participación y promociones en modo demo
6. Integración progresiva con datos reales de la API
7. Widget Android en una fase posterior

## Package provisional

`com.alecz.somosradio`

El package es provisional mientras el proyecto siga siendo una propuesta no oficial.
