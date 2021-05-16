#!/bin/sh
repo_path=$1
branch=$2

if [ ! -d "$repo_path" ]
then
    printf "[ERROR] No repo path found.\n"
    exit 1
fi

if [ -z "$branch" ]
then
    printf "[ERROR] No branch given.\n"
    exit 1
fi

assureRepo()
{
    git status > /dev/null 2>&1

    if [ $? -ne 0 ]
    then
        printf "[ERROR] Repo doesn't exist.\n"
        exit 1
    fi
}

syncRepo()
{
    git fetch -ap > /dev/null 2>&1
    git pull > /dev/null 2>&1
}

checkoutBranch()
{
    branch=$1

    git checkout -b testing "origin/$branch" > /dev/null 2>&1

    if [ $? -ne 0 ]
    then
        printf "[ERROR] Branch doesn't exist.\n"
        exit 1
    fi
}

check()
{
    # Build artifacts
    make > /dev/null 2>&1
    build_status=$?

    if [ $build_status -ne 0 ]
    then
        printf "[ERROR] Build failed.\n"
        exit 1
    fi

    # Run tests on artifacts
    check_output=`make check 2>&1`
    check_status=$?

    # Clean artifacts
    make clean > /dev/null 2>&1
    clean_status=$?

    if [ $clean_status -ne 0 ]
    then
        printf "[ERROR] Clean failed.\n"
        exit 1
    fi

    printf "$check_output\n"

    cleanupBranch
    exit $check_status
}

cleanupBranch()
{
    git checkout master > /dev/null 2>&1
    git branch -d testing > /dev/null 2>&1
}

cd "$repo_path"
assureRepo
syncRepo
checkoutBranch "$branch"
check
