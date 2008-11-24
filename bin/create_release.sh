#!/bin/sh

print_usage () {
    echo "Usage: $0 <version> <source branch>"
}

# check the arguments
VERSION=$1
if [ -z $VERSION ]; then
    print_usage
    exit 1
fi

SOURCE=$2
if [ -z $SOURCE ]; then
    print_usage
    exit 1
fi

# be sure the checkout is up to date
svn up
if [ $? -gt 0 ]; then
    echo "SVN updating failed, aborting tagging process."
    exit 1
fi

TAG="tags/pldatabase-$VERSION"

# verify the tag is new
if [ -d $TAG ]; then
    echo "Tag $TAG already exists, aborting."
    exit 1
fi

# create the tag
svn cp $SOURCE $TAG 
if [ $? -gt 0 ]; then
    echo "Creating the tag failed, aborting tagging process."
    exit 1
fi

# Build the documentation
pushd .
cd $TAG
doxygen

# validate the build worked
if [ $? -gt 0 ]; then
    echo "Build failed, aborting tagging process."
    exit 1
fi

# back down to the root
popd

# add the docs to the tag since we need these to be served on google code
svn add $TAG/docs

# fix up the svn mimetypes for the html [needed by google code]
find $TAG/docs -name \*.html -exec svn propset svn:mime-type text/html {} \;
