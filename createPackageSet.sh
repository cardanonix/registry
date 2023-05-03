#!/usr/bin/env bash
input_file_url="https://api.github.com/repos/cardanonix/registry/contents/package-sets/15.0.0.json"
output_file="generated_package_info.nix"

echo "Please enter your GitHub personal access token: "
read -r GITHUB_ACCESS_TOKEN
export GITHUB_ACCESS_TOKEN

input_file_content=$(curl -s -H "Authorization: token $GITHUB_ACCESS_TOKEN" $input_file_url | jq -r '.content' | base64 --decode)

echo "{" > $output_file

for package_name in $(echo "$input_file_content" | jq -r '.packages | keys[]'); do
    package_version=$(echo "$input_file_content" | jq -r ".packages.\"$package_name\"")
    metadata_file_url="https://api.github.com/repos/cardanonix/registry/contents/metadata/$package_name.json"
    metadata_file_content=$(curl -s -H "Authorization: token $GITHUB_ACCESS_TOKEN" $metadata_file_url | jq -r '.content' | base64 --decode)
    repo_owner=$(echo "$metadata_file_content" | jq -r ".location.githubOwner")
    repo_name="purescript-$(echo "$metadata_file_content" | jq -r ".location.githubRepo")"
    ref=$(echo "$metadata_file_content" | jq -r ".published.\"$package_version\".ref")

    spago_dhall_url="https://api.github.com/repos/$repo_owner/$repo_name/contents/spago.dhall?ref=$ref"
    spago_dhall_content=$(curl -s -H "Authorization: token $GITHUB_ACCESS_TOKEN" $spago_dhall_url | jq -r '.content' | base64 --decode)
    dependencies=$(echo "$spago_dhall_content" | sed -n '/dependencies =/,/\]/p' | sed -e '1d;$d' | tr -d '[]",' | xargs)

    echo "  $package_name =" >> $output_file
    echo "  {" >> $output_file
    echo "    src.git =" >> $output_file
    echo "      {" >> $output_file
    echo "        repo = \"https://github.com/$repo_owner/$repo_name.git\";" >> $output_file
    echo "        rev = \"$ref\";" >> $output_file
    echo "      };" >> $output_file
    echo "    info =" >> $output_file
    echo "      {" >> $output_file
    echo "        version = \"$package_version\";" >> $output_file
    echo "        dependencies = [" >> $output_file
    for dependency in $dependencies; do
        echo "          \"$dependency\"" >> $output_file
    done
    echo "        ];" >> $output_file
    echo "      };" >> $output_file
    echo "  };" >> $output_file
done

echo "}" >> $output_file