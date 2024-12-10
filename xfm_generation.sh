#!/usr/bin/env bash

# Generates template space transformation assets via ANTs
#
# Synchon Mandal 2024, Forschungszentrum Juelich GmbH

# Exit when a command fails
set -o errexit
# Fail when accessing unset variables
set -o nounset
# Fail when even one command in pipeline fails
set -o pipefail
# Allow debug by using `TRACE=1 ./xfm_generation.sh`
[[ "${TRACE-0}" == "1" ]] && set -o xtrace

# Help command
if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    cat <<USAGE

Generates human template space transformation assets via ANTs. Template space
names are according to `templateflow <https://www.templateflow.org/browse/>`
without the `tpl-`.

Usage:

  ./xfm_generation.sh -f <src-template-space-t1w> -t <target-template-space-t1w>

    -f <src-template-space-t1w>    Source template space (e.g., MNI152NLin2009cAsym)
    -t <target-template-space-t1w> Target template space (e.g., MNI152NLin6Asym)

USAGE
    exit
fi

# Logging helper function
logit() {
  echo "$(date -u) $1";
}

# Assert datalad exists
assert_datalad_exists() {
  command -v datalad &> /dev/null || { logit "ERROR Datalad could not be found!"; exit 1; }
  logit "INFO Datalad found, proceeding to get data...";
}

# Assert antsRegistration exists
assert_antsRegistration_exists() {
  command -v antsRegistration &> /dev/null || { logit "ERROR antsRegistration could not be found!"; exit 1; }
  logit "INFO antsRegistration found, proceeding...";
}

main() {

    while getopts ":f:t:" opt; do
        case $opt in
            f)
                src_path=$OPTARG
                logit "DEBUG Source template path: ${src_path}"
                ;;
            t)
                target_path=$OPTARG
                logit "DEBUG Target template path: ${target_path}"
                ;;
            \?)
                logit "ERROR Invalid option: -$OPTARG"
                exit 1
                ;;
            :)
                logit "ERROR Option -$OPTARG requires an argument"
                exit 1
                ;;
        esac
    done

    assert_datalad_exists;
    assert_antsRegistration_exists;

    src_name=$(basename $(dirname $src_path));
    IFS="-"; arr_src_name=($src_name); unset IFS;
    target_name=$(basename $(dirname $target_path));
    IFS="-"; arr_target_name=($target_name); unset IFS;
    output_dir_prefix="${arr_src_name[1]}_to_${arr_target_name[1]}";
    logit "DEBUG Output directory prefix: ${output_dir_prefix}";

    # Resolve symlinks
    full_src_path=$(realpath "$src_path");
    logit "DEBUG Resolved source template path: ${full_src_path}";
    full_target_path=$(realpath "$target_path");
    logit "DEBUG Resolved target template_path: ${full_target_path}";

    # Create output directory if not found and change directory
    mkdir -p "xfms/${output_dir_prefix}";
    cd "${PWD}/xfms/${output_dir_prefix}";

    antsRegistration \
        --verbose 1 \
        --dimensionality 3 \
        --float 0 \
        --collapse-output-transforms 1 \
        --output $output_dir_prefix \
        --interpolation Linear \
        --use-histogram-matching 0 \
        --winsorize-image-intensities [ 0.005,0.995 ] \
        --initial-moving-transform [ $full_src_path,$full_target_path,1 ] \
        --transform Rigid[ 0.1 ] \
        --metric MI[ $full_src_path,$full_target_path,1,32,Regular,0.25 ] \
        --convergence [ 1000x500x250x0,1e-6,10 ] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0vox \
        --transform Affine[ 0.1 ] \
        --metric MI[ $full_src_path,$full_target_path,1,32,Regular,0.25 ] \
        --convergence [ 1000x500x250x0,1e-6,10 ] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0vox \
        --transform SyN[ 0.1,3,0 ] \
        --metric MI[ $full_src_path,$full_target_path,1,32] \
        --convergence [ 100x70x50x0,1e-6,10 ] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0vox \
        --write-composite-transform 1

    # Change to root
    cd ../../;

    logit "INFO Done. Data in ${PWD}/xfms/${output_dir_prefix}";
}

main "$@"
