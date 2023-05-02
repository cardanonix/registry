#!/usr/bin/env bash

input_file="package-sets/15.0.0.json"
output_file="generated_package_info.nix"

echo "{" > $output_file

for package_name in $(jq -r '.packages | keys[]' $input_file); do
    package_version=$(jq -r ".packages.\"$package_name\"" $input_file)
    metadata_file="metadata/$package_name.json"
    repo_owner=$(jq -r ".location.githubOwner" $metadata_file)
    repo_name=$(jq -r ".location.githubRepo" $metadata_file)
    ref=$(jq -r ".published.\"$package_version\".ref" $metadata_file)
    
    echo "  $package_name =" >> $output_file
    echo "  {" >> $output_file
    echo "    src.git =" >> $output_file
    echo "      {" >> $output_file
    echo "        repo = \"https://github.com/$repo_owner/$repo_name.git\";" >> $output_file
    echo "        rev = \"$ref\";" >> $output_file
    echo "      };" >> $output_file
    echo "  };" >> $output_file
done

echo "}" >> $output_file