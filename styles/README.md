How to compile the Bootstrap styles
===================================

1. Install Node JS and NPM using homebrew

    brew doctor
    brew update
    brew install node

2. Install `recess`

    npm install recess -g

3. Edit the values in `project.less` as you see fit, then either

    recess bootstrap.less --compile > bootstrap.css
    
    or
    
    recess bootstrap.less --compress > bootstrap.min.css

