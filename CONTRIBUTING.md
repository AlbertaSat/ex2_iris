# CONTRIBUTION GUIDLINES

## General Guidelines

* All code must have full unit test coverage.
* Create a feature branch when you are working on code. Make a new branch for every new feature you will add. Include your name and your 
feature. For example, make a branch called Collin-mNLP_Driver to develop the mNLP driver. See https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow
* When your branch is ready to be merged into master, request that the code be pulled for review.  Expect some back and forth on this. Your branch is yours to manage, but pushing to master requires authorization.
* Commit messages should be meaningful. Say what you did and why, include new files, new functions, and any major bugs. One or two sentences is usually enough. If you need more than that, then you need to commit more frequently.
* If you are not sure, YOU MUST ASK.


## Preamble

All authored content must unclude as a block comment an appropriate preamble including copyright and licence information. For a C file, this looks like:

    /*
     * Copyright (C) 2015  University of Alberta
     *
     * This program is free software; you can redistribute it and/or
     * modify it under the terms of the GNU General Public License
     * as published by the Free Software Foundation; either version 2
     * of the License, or (at your option) any later version.
     *
     * This program is distributed in the hope that it will be useful,
     * but WITHOUT ANY WARRANTY; without even the implied warranty of
     * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     * GNU General Public License for more details.
     */
	 
All source code files must also contain a file name, list of authors (comma delimited), and a date of creation in the following format:

    /**
	 * @file <file_name>.<ext>
	 * @author <author_names>
	 * @date YYYY-MM-DD
	 */
	 
## C-specific Guidelines

### Function Headings

Function must be catalogued in their heading according to the following format:

	/**
	 * @brief
	 * 		<breif (one line) description of the function>
	 * @details
	 * 		<more detailed description of the function>
	 * @attention
	 * 		<if applicable, any comments or concerns regarding the function>
	 * @param <argument_1>
	 * 		<if applicable, brief (one line) description of one of the function's arguments>
	 * @param <argument_2>
	 * 		<if applicable, brief (one line) description of one of the function's arguments>
	 * @return
	 * 		<if applicable, brief description of what is returned by the function>
	 */
	 
### Prevent Multiple Inclusions

All header files should have preprocessor checking to prevent multiple inclusions:

	#ifndef FILENAME_H
	#define FILENAME_H

	/* Source code goes here */

	#endif /* FILENAME_H_ */

The header file should have the minimum required #includes possible. If a file is included because it is required for the implementation of the source file, then that file should be included in the source file, not the header file.

### Commenting

Comments on source code should emphasize why the code is there. A programmer reading the code should understand what it does and why it is there. See the relevant sections of the [Google style guide](https://google.github.io/styleguide/cppguide.html#Comments).


* Function prototypes, and implementations should always have a description.
* All data structures should have a description explaining what each of their members is used for.
* All variables, no matter what their scope is, should have comments explaining their purpose where they are declared.


### Variable Naming

The variable or function name begins with a lower-case letter and the start of a subsequent word begins with a capital letter, and abbreviations are all capital and separated by an ‘_’. When variables are declared their names should be aligned with one another. See this example:

    int     exampleOne;
	char    *exampleTwo;
	short   exampleThree_SYS;
	
The name of a variable should avoid abbreviations unless the abbreviation is well known or has comments explaining the abbreviation.

All macros should be named using all capital letters, with each word in the name separated by an ‘_’. Macros should never start with an ‘_’, and should never start, and/or end with a “__” (double underscore). Macros that imitate a function call can be written using the naming convention for functions. For example:

    #define MAX_PACKETS 6
	#define exampleFunction(int arg1,int arg2)

### Coding Standards

* C source code style is loosely based on "The GNU Coding Standards" (Copyright (C) 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 Free Software Foundation, Inc.)
(Full text available here: [https://www.gnu.org/prep/standards/standards.html]

## VHDL Guidelines

The general goal of these contribution guidelines is VHDL code that is clear, consistant, reasonably performant. It is *not* to create a list of standards that must be applied in every situation. Use your best judgement.

In general we will be following [this](https://www.so-logic.net/en/knowledgebase/fpga_universe/tutorials/vhdl_style_guide) vhdl style guide, some important parts of which are summarized as follows:

* Everything (variables, constants, etc.) is in `snake_case`.
* Type definitions that are used multiple times should go in packages.
* Do not use default values for signals and variables except in testbench files, as this can cause a mismatch between simulation and synthesis.
* State machines should use the three-process method to minimize latency and improve readability (but don't do this if it makes your code *harder* to understand).

Additionally:
* Entity declarations should include a block comment that describes their function and parameters
* VHDL can be unit-tested by using testbench files and the `assert` keyword to ensure the correct output is generated.
