#!/bin/bash

# Iconos Unicode
CHECK_ICON=$'\xe2\x9c\x85'  # ✅
CROSS_ICON=$'\xe2\x9d\x8c'  # ❌
RIGHT_ARROW=$'\xe2\x9e\xa1'  # ➡
HEAVY_CHECK_MARK=$'\xe2\x9c\x94'  # ✔
OPEN_FILE_FOLDER=$'\xf0\x9f\x93\x82'  # 📂

preguntar_y_evaluar() {
  local pregunta="$1"
  local mensaje_continuar="$2"
  local mensaje_salir="$3"

  echo -e "\n_____________________________________________________________________________________"
  echo -e "$pregunta"
  read -p "¿Desea continuar? (presione Enter para continuar, cualquier otra tecla para salir): " respuesta

  if [ -z "$respuesta" ]; then
      echo -e "$mensaje_continuar"
      echo -e "_____________________________________________________________________________________"
      # Agregar aquí las operaciones adicionales si el usuario elige continuar
  else
      echo -e "$mensaje_salir"
      echo -e "_____________________________________________________________________________________"
      exit 0
  fi
}

updated-branch-git-repository() {

  local local_branch="$1"
  local origin_merge_local="$2"

  echo -e "$HEAVY_CHECK_MARK to Upgrade (local): $local_branch"
  echo -e "$HEAVY_CHECK_MARK for merge (remote): $origin_merge_local"
  echo -e "******************** $origin_merge_local $RIGHT_ARROW $local_branch ********************"

  preguntar_y_evaluar "Confirmar Ramas" "Continuing with the script...\n" "Cancellation... Exit del script..."

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

  preguntar_y_evaluar "$RIGHT_ARROW git checkout $local_branch" "Continuing with the script...\n" "Cancellation... Exit del script..."
  echo -e "$pregunta"
  git checkout $local_branch

  preguntar_y_evaluar "$RIGHT_ARROW git pull origin $local_branch" "Continuing with the script...\n" "Cancellation... Exit del script..."
  echo -e "$pregunta"
  git pull origin $local_branch

  preguntar_y_evaluar "$RIGHT_ARROW git merge origin/$origin_merge_local" "Continuing with the script...\n" "Cancellation... Exit del script..."
  echo -e "$pregunta"
  git merge origin/$origin_merge_local


  preguntar_y_evaluar "$RIGHT_ARROW ************** git push origin $local_branch **************" "Continuing with the script...\n" "Cancellation... Exit del script..."
  echo -e "$pregunta"
  git push origin $local_branch

  # Fin del script
  echo -e "\n ${CHECK_ICON}  Operaciones completadas."

}



# Mostrar mensaje de inicio
echo -e "\n${OPEN_FILE_FOLDER} Updated Remote Project"

# Mostrar las ramas ingresadas
echo -e "\n____________________________________"
echo -e "${CHECK_ICON}  Check Branches"
# Solicitar la rama local o remota a actualizar
  read -p "$RIGHT_ARROW Branch to Upgrade (local): " a

  # Solicitar la rama para el merge
  read -p "$RIGHT_ARROW Branch for merge (remote): " b

updated-branch-git-repository $a $b