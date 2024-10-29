username=$1
password=$2
location=$3

if [ $# -eq 0 ]; then
  echo "Usage: $0 <username> <password> <location> <number of commits to check>"
  exit 1
fi

mkdir build 2> /dev/null
git show -n "$4" --name-only | grep "/challenge/" | sed 's|\(.*challenge\)/.*|\1|' | uniq > build/changes.txt

echo "+++CHALLENGES EDITED: "
cat build/changes.txt

echo "----- ----- -----"
echo "+++LOGGING INTO DOCKERHUB"
echo "$password" | docker login -u "$username" --password-stdin http://us-central1-docker.pkg.dev
echo "----- ----- -----"

changes=$(cat build/changes.txt)
IFS=$'\n'
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
            echo "+++BUILDING: $location/$repo"
            docker build -t "$location/$repo" . || \
                sudo docker build -t "$location/$repo" .

        } && {
            echo "+++BUILD SUCCESS"
            echo "+++PUSHING: $location/$repo"
            docker push "$location/$repo" || \
                sudo docker push "$location/$repo"
        } || {
            echo "+++FAILED: $username/$repo"
        }
        
        cd "$(git rev-parse --show-toplevel)"
        
        echo "----- ----- -----"

    fi
done
