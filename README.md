
## wMaker
Analog of so-called 'make' in Java Script.

## Installation
```terminal
npm install wmaker
```

## Usage
### Options
* opt { object }[ optional ] - structure for storing user defined variables.
* target { object } - structure for storing make recipes.

<!-- #### Opt Description will be here-->

#### Target
|  Property 	| Type  	|  Default 	| Description  	|
|---	|---	|---	|---	|
|name |string| '' |Current target name.
|shell|string|null|Commands to execute in comand prompt.
|after|array/string|null|Files for validation and "up-to-date" check with files from 'before'. Validation - check whether all files from this list exists. "Up-to-date" means that any file from 'after' property is newer then other any file from 'before'.
|before|array/string|null|Dependencies( files/targets ) that must checked for "up-to-date" before recipe execution.If recipe is "up-to-date" it will not be executed.
|pre|function|null|Function called at the beginning of recipe execution.
|post|function|null|Function called at the ending of recipe execution.

### Methods
* make -
* makeTarget -
* targetAdjust -
* targetsAdjust -
* targetInvestigateUpToDate -
* targetInvestigateUpToDateRecipe -
* targetInvestigateUpToDateFile -
* pathesFor : pathesFor -

##### Example #1
```javascript

```

