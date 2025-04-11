# AlaSQL and AlaFile node-red nodes

(c) 2017 Mathias Rangel Wulff, Andrey Gershun & Kim McKinley 

## node-red-contrib-alasql

The Node-red `alasql` node lets you access javascript objects as if they were a SQL database. The `alafile in/out` nodes lets you transform the AlaSQL results into .xlsx, .xls, .csv, .json, .tab, .tsv, or .txt files stored on the node-red server.

The package is a Node-red wrapping of [AlaSQL](https://github.com/agershun/alasql) providing fast SQL based in-memory data processing for BI and ERP applications and import-export files into XLSX, XLS, and other data formats. Especially useful when you have (many) different sources coming with data you want to join, filter and format.



## Install

Go to your Node-RED user directory and install `node-red-contrib-alasql` from npm:

```bash
cd ~/.node-red
npm install node-red-contrib-alasql
```

## How to use an AlaSQL node

1. Write a valid SQL query in the `SQL query` parameter. It can hold several SQL queries separated by `;`.

2. Refer to input data in `msg.payload` with `$0` in your SQL. If `msg.payload` is an array the first value will be `$0`, the second `$1` and so forth. 

2. The result will be returned in `msg.payload`

#### Returned values

Default return format is an array of objects:  

```js
[{name:'foo', age: 86}, {name:'bar', age:64}]
```

To manipulate output format please consult the use of [`VALUE OF`](https://github.com/agershun/alasql/wiki/Value), [`MATRIX OF`](https://github.com/agershun/alasql/wiki/MATRIX), [`COLUMN OF`](https://github.com/agershun/alasql/wiki/COLUMN), [`ROW OF`](https://github.com/agershun/alasql/wiki/ROW), and [`RECORDSET OF`](https://github.com/agershun/alasql/wiki/RECORDSET).

If several queries are executed (separated by `;`) the returned value will be an array with the result from each.



##  So - what can I do?

Execute SQL on your data and output the result. 

This includes `INSERT`, `UPDATE`, `DELETE`, `VIEW` indexes and multiple levels of `JOIN`, `GROUP BY`, `UNION`, `ROLLUP()`, `CUBE()`, `GROUPING SETS()`, `CROSS APPLY`, `OUTER APPLY`, `WITH SELECT`, and subqueries. See the wiki to [compare supported features with SQL standards](https://github.com/agershun/alasql/wiki/SQL%20keywords).

Please [consult the AlaSQL wiki](https://github.com/agershun/alasql/wiki/readme) to understand the flexible nature of the library. 


## AlaFile - Import and Export files

You also can use `alafile` component to perform import and export operations with files. The parameters include:

* `Name` - the name of the node
* `File name` - path to import or export file
* `Format` - select file format 
* `Colums` - specify `*` (star) for all columns or list them with comma like `one, two, three`. You also can use AlaSQL functions or even rename columns with `AS` operator (see the AlaSQL `SELECT` statement documentation)
* `Headers` - include first line headers

## Test Suite
The *node-red-contrib-alasql test suite* for AlaSQL flows is provided to ensure AlaSQL nodes are operating properly. 


*node-red-contrib-alasql* contains a set of test flows to ensure the nodes are
handling exceptions properly and running as expected. Existing flows can be exported/imported into the test suite for verification.


The test suite is kindly contributed by
[Kim McKinley (PotOfCoffee2Go)](http://github.com/potofcoffee2go). Requests and comments are appreciated. Create an 
[issue](https://github.com/AlaSQL/node-red-contrib-alasql/issues) and please mention `@PotOfCoffee2Go` somewhere in the issue.




### Running Alasql Test Suite
To run the Test Suite from an existing node-red installation that uses `node-red-contrib-alasql` please do:

```
cd ~/.node-red/node_modules/node-red-contrib-alasql
npm run test-setup
npm test
```

This will 

1. Create a node-red user directory containing AlaSQL test flows of
the version installed in ~/.node-red
2. Setup the needed files for testing
3. Start the test serving on port 8081

Next time you want to run your test you can skip step 2.

To change the port do a `export PORT=8081` on Mac or `set PORT=8081` on Win prior to running `npm test`.


### Running stand alone Test Suite
If you wish to test the current release of AlaSQL prior to going into production.
In any directory:

```
git clone https://github.com/AlaSQL/node-red-contrib-alasql.git
cd node-red-contrib-alasql
npm install
npm run test-setup
npm test

```

The test suite uses the `npm link` command which allows node-red to
automatically add *AlaSQL* nodes to node-red by default. To remove this behaviour,
issue a `npm unlink` from the *node-red-contrib-alasql* directory cloned above.



## Please note

As default the library works in-memory - so all unsaved data are reset when Node-RED closes. Please consult [the wiki](https://github.com/agershun/alasql/wiki) to read more about how to let data be persistent.  

If you are not sure why this is funny - please find out more about "SQL injections":

![xkcd](https://cloud.githubusercontent.com/assets/1063454/13614823/999e9548-e572-11e5-9661-57a06e8f3fa4.png)




