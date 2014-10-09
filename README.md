#MySQL Database Handler

Avocadorm database handler for a [MySQL](http://www.mysql.com/) database. It uses [SQLJocky](https://pub.dartlang.org/packages/sqljocky)
to talk to the database.

*  [Homepage](http://www.magnetfruit.com/databasehandler)
*  [GitHub Repository](https://github.com/magnetfruit/mysql_database_handler)
*  [Pub package](https://pub.dartlang.org/packages/magnetfruit_mysql_database_handler)

##Creating a database handler
The information required by the MySqlDatabaseHandler constructor is

-  the IP and port of the database server
-  the database name
-  the user and password under which the operations will be made

For example:

```dart
var databaseHandler = new MySqlDatabaseHandler('localhost', 3306, 'db_name', 'guest', 'password');
```

The database handler instance can then be used to construct the avocadorm.

```dart
var avocadorm = new Avocadorm(databaseHandler);
```

##Dependency
Add the dependency in your *pubspec.yaml*. For example:

```
dependencies:
  magnetfruit_mysql_database_handler: ">=0.1.0 <0.2.0"
```
