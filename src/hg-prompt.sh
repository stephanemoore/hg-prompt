# Mercurial prompt support
#
# Copyright (c) 2018 Stephane Moore
# Distributed under the MIT License.

# Constructs a prompt string for the Mercurial repository containing the current working directory
# or nothing if the current working directory is not within a Mercurial repository.
__hg_ps1() {
  local exit_code=$?

  local hg_root="$(hg root 2>/dev/null)"

  if [ -z "${hg_root}" ]; then
    return ${exit_code}
  fi

  # Show * for modified files, + for added files, and % for untracked files.
  local hg_display_modifiers=""
  local hg_status_summary="$(hg status | cut -c 1)"
  if [[ "${hg_status_summary}" =~ .*M.* ]]; then
    hg_display_modifiers="${hg_display_modifiers}*"
  fi
  if [[ "${hg_status_summary}" =~ .*A.* ]]; then
    hg_display_modifiers="${hg_display_modifiers}+"
  fi
  if [[ "${hg_status_summary}" =~ .*\?.* ]]; then
    hg_display_modifiers="${hg_display_modifiers}%"
  fi

  # Begin constructing the prompt string moving backwards.
  local hg_prompt=""
  if [ "${hg_display_modifiers}" != "" ]; then
    hg_prompt=" ${hg_display_modifiers}"
  fi

  # Check for an active bookmark.
  local hg_current_bookmark="${hg_root}/.hg/bookmarks.current"
  if [ -e "${hg_current_bookmark}" ]; then
    local hg_bookmark_name=$(cat "${hg_current_bookmark}")
    hg_prompt="${hg_bookmark_name}${hg_prompt}"
    printf -- "$1" "${hg_prompt}"
    return ${exit_code}
  fi

  # Check for a tag on the current commit.
  local hg_tags="$(hg log -r . --template '{tags}')"
  local hg_tag_array=( $hg_tags )
  if [ ${#hg_tag_array[@]} -ne 0 ]; then
    for hg_tag in "${hg_tag_array[@]}"
    do
      if [ "${hg_tag}" != "tip" ]; then
        hg_prompt="${hg_tag}${hg_prompt}"
        printf -- "$1" "${hg_prompt}"
        return ${exit_code}
      fi
    done
  fi

  # In the absence of other information, simply display the changeset identifier.
  local hg_changeset_id_hash="$(hg log -r . --template '({node})')"
  hg_prompt="${hg_changeset_id_hash}${hg_prompt}"
  printf -- "$1" "${hg_prompt}"
  return ${exit_code}
}
