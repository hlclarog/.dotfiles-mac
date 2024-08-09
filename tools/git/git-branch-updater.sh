#!/bin/bash

# Iconos Unicode
CHECK_ICON=$'\xe2\x9c\x85'  # ✅
CROSS_ICON=$'\xe2\x9d\x8c'  # ❌
RIGHT_ARROW=$'\xe2\x9e\xa1'  # ➡
HEAVY_CHECK_MARK=$'\xe2\x9c\x94'  # ✔
OPEN_FILE_FOLDER=$'\xf0\x9f\x93\x82'  # 📂

# Definir variables para las ramas
DEV="" #devel
BETA="beta"
MASTER="" #master

# Variable para omitir preguntas
OMITIR_PREGUNTAS=false
PUSH_ORIGIN_END=false

preguntar_y_evaluar() {
  local pregunta="$1"
  local mensaje_continuar="$2"
  local mensaje_salir="$3"

  echo -e "\n______________________________________________________________________________"
  echo -e "$pregunta"
  read -r -p "¿Desea continuar? (Enter para continuar, otra tecla para salir): " respuesta

  if [ -z "$respuesta" ]; then
    echo -e "$mensaje_continuar"
    echo -e "=============================================================================="
  else
    echo -e "$mensaje_salir"
    echo -e "=============================================================================="
    exit 0
  fi
}

updated_branch_git_repository() {
  echo -e "\n###############################################################################"

  local local_branch="$1"
  local origin_merge_local="$2"

  echo -e "$HEAVY_CHECK_MARK to Upgrade (local): $local_branch"
  echo -e "$HEAVY_CHECK_MARK for merge (remote): $origin_merge_local"
  echo -e "******************** $origin_merge_local $RIGHT_ARROW $local_branch ********************"

  if [ "$OMITIR_PREGUNTAS" != true ]; then
    preguntar_y_evaluar "Confirmar Ramas" "Continuando con el script...\n" "Cancelación... Saliendo del script..."
  else
    echo -e "\n______________________________________________________________________________"
  fi

  if git rev-parse --verify $origin_merge_local > /dev/null 2>&1; then
    git checkout $origin_merge_local
    git pull origin $origin_merge_local
    echo -e "$CHECK_ICON  La rama origin fue actualizada en local '$origin_merge_local'."
  fi

  # Validar si la rama local existe, de lo contrario, traerla del origin
  if git rev-parse --verify $local_branch > /dev/null 2>&1; then
    echo -e "$CHECK_ICON  La rama local '$local_branch' existe."
  else
    echo -e "$CROSS_ICON  La rama local '$local_branch' no existe. Se creará a partir de 'origin/$local_branch'."

    if git rev-parse --verify "origin/$local_branch" > /dev/null 2>&1; then
      git checkout -b $local_branch origin/$local_branch
      echo -e "$CHECK_ICON  Rama local '$local_branch' creada exitosamente."
    else
      echo -e "$CROSS_ICON  La rama remota 'origin/$local_branch' no existe. No se puede crear la rama local."
      exit 0
    fi
  fi

  # Realizar las operaciones deseadas con las ramas
  if [ "$OMITIR_PREGUNTAS" != true ]; then
    preguntar_y_evaluar "$RIGHT_ARROW git checkout $local_branch" "Continuando con el script...\n" "Cancelación... Saliendo del script..."
  else
    echo -e "\n______________________________________________________________________________"
  fi
  git checkout $local_branch

  if [ "$OMITIR_PREGUNTAS" != true ]; then
    preguntar_y_evaluar "$RIGHT_ARROW git pull origin $local_branch" "Continuando con el script...\n" "Cancelación... Saliendo del script..."
  else
    echo -e "\n______________________________________________________________________________"
  fi
  git pull origin $local_branch

  if [ "$OMITIR_PREGUNTAS" != true ]; then
    preguntar_y_evaluar "$RIGHT_ARROW git merge origin/$origin_merge_local" "Continuando con el script...\n" "Cancelación... Saliendo del script..."
  else
    echo -e "\n______________________________________________________________________________"
  fi
  git merge origin/$origin_merge_local

  if [ "$OMITIR_PREGUNTAS" != true ] || [ "$PUSH_ORIGIN_END" != false ]; then
    preguntar_y_evaluar "$RIGHT_ARROW ************** git push origin $local_branch **************" "Continuando con el script...\n" "Cancelación... Saliendo del script..."
  else
    echo -e "\n______________________________________________________________________________"
  fi
  git push origin $local_branch

  # Fin del script
  echo -e "\n${CHECK_ICON}  Operaciones completadas."
  echo -e "\n______________________________________________________________________________\n"
}

mostrar_menu() {
  echo "Seleccione una opción:"
  echo "1) Actualización de $DEV"
  echo "2) Actualización de $BETA"
  echo "3) Actualización de $MASTER"
  echo "4) Manual"
  read -r -p "Ingrese el número de la opción: " opcion
}

preguntar_check_push_origin() {
  read -p "¿Check de Cambios git push origin? (s/n): " RESPUESTA_CHECK_PUSH_ORIGIN_END
  if [[ "$RESPUESTA_CHECK_PUSH_ORIGIN_END" =~ ^[sS]$ ]]; then
    PUSH_ORIGIN_END=true
    echo "Check de Cambios git push origin $local_branch activado."
  else
    PUSH_ORIGIN_END=false
    echo "Check de Cambios git push origin $local_branch desactivado."
  fi
}

preguntar_omitir_preguntas() {
  read -p "¿Desea omitir las preguntas de confirmación? (s/n): " respuesta_omitir
  if [[ "$respuesta_omitir" =~ ^[sS]$ ]]; then
    OMITIR_PREGUNTAS=true
    echo "Omitir preguntas ha sido activado."
  else
    OMITIR_PREGUNTAS=false
    echo "Omitir preguntas ha sido desactivado."
  fi
}

# Mostrar mensaje de inicio
echo -e "\n###############################################################################"
echo -e "\n${OPEN_FILE_FOLDER} Updated Remote Project"
echo -e "===>${CHECK_ICON}  Check Branches"

# Mostrar el menú
mostrar_menu

# Procesar la opción seleccionada
case $opcion in
  1)
    preguntar_omitir_preguntas
    preguntar_check_push_origin
    updated_branch_git_repository $DEV $BETA
    updated_branch_git_repository $DEV $MASTER
    ;;
  2)
    preguntar_omitir_preguntas
    preguntar_check_push_origin
    updated_branch_git_repository $BETA $DEV
    ;;
  3)
    preguntar_omitir_preguntas
    preguntar_check_push_origin
    updated_branch_git_repository $MASTER $BETA
    ;;
  4)
    preguntar_omitir_preguntas
    read -r -p "$RIGHT_ARROW Branch to Upgrade (local): " A
    read -r -p "$RIGHT_ARROW Branch for merge (remote): " B
    preguntar_check_push_origin
    updated_branch_git_repository "$A" "$B"
    ;;
  *)
    echo "Opción no válida. Saliendo..."
    exit 1
    ;;
esac
