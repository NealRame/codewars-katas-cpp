codewars-cpp-katas
==================

This repository offers the boilerplate code needs to train on codewars' Kata.

Requirement
-----------

You will need _[conan](https://conan.io)_ to be installed. The easiest way to
setup conan is to open a terminal and execute the followind command:

```shell
$ pip3 install conan
```

_[VS Code](https://code.visualstudio.com)_ is not mandatory but it is
recommended. A __*.vscode*__ configuration is also supplied and provide a task
to create new Codewars Katas training.

Create a new Kata training
--------------------------

A script is provided to add a new Kata.

## Using the command line

#### Synopsis
```
Kata.sh <KATA_NAME>
```

#### Parameters
* `KATA_NAME` - name of the kata.

#### Example
```shell
$ cd "/path/to/codewars-cpp-repository"
$ chmod + x "./Scripts/Kata.sh"
$ mkdir -p Build
$ "./Scripts/Kata.sh "$PWD" "Name of Your Kata"
```

You will find the katas in the `Katas` folder of the repository. The kata
filename will be the name you provided when creating the Kata with all spaces
removed and the `.cpp` extension added.

## Using VS Code
Run the task "Create new Kata ..." then specify a Kata name when promped for it
and you're ready to train.

Train
-----

All Katas respect the following template :

```cpp
// begin of kata --------------------------------------------------------------

// end of kata ✄ --------------------------------------------------------------

#define CATCH_CONFIG_MAIN
#include <catch2/catch.hpp>

TEST_CASE( "Kata: " "NAME OF THE KATA" ) {
    // Put your tests below
}
```

Test are written using [Catch2](https://github.com/catchorg/Catch2/blob/master/docs/tutorial.md#top) testing framework.