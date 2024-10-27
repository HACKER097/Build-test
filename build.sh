username="truegav"
password=$(cat "$HOME/Desktop/archive/dockerhub")


mkdir build 2> /dev/null
git show -n 10 --name-only | grep "/challenge/" | sed 's|\(.*challenge\)/.*|\1|' | uniq > build/changes.txt


# echo "+++CHALLENGES EDITED: "
# cat build/changes.txt

echo "----- ----- -----"
echo "+++LOGGING INTO DOCKERHUB"
echo "$password" | docker login -u "$username" --password-stdin
echo "----- ----- -----"

changes=$(cat build/changes.txt)
for d in $changes; do
    if [ -e "$d/Dockerfile" ]; then 
        echo "+++DOCKER FILE FOUND IN: $d"
        echo "+++CHANGING DIRECTORY TO: $d"
        cd "$d"

        # Remove special chars, replace space with _
        repo=$(basename "$(dirname "$PWD")" | sed 's/[^a-zA-Z0-9 ]//g; s/ /_/g' | tr '[:upper:]' '[:lower:]')
        # Run block 2 if block 1 is a success
        # Run block 3 if block 1 fails
        # Error code of only the last line is used
        {
            echo "+++BUILDING: $username/$repo"
            docker build -t "$username/$repo" . || \
                sudo docker build -t "$username/$repo" .

        } && {
            echo "+++BUILD SUCCESS"
            echo "+++PUSHING: $username/$repo"
            docker push "$username/$repo" || \
                sudo docker push "$username/$repo"
        } || {
            echo "+++FAILED"
        }
        
    
    fi
done
