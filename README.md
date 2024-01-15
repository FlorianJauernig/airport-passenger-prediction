In this project, the features of 6.000 airports are analyzed and a subset of 2000 commercial airports with available passenger data is used to to predict passenger numbers.
Two files are included in this repository:

* db_data.sql: This SQL script was used to create and fill the relevant database tables and reduce the dataset from originally 56.000 airports to 6.000 airports by removing airports that are not suitable for or accessible to commercial airplanes, for example heliports, seaplane bases, military airports or airports with unpaved runways.
* airports.ipynb: Jupyter notebook with Python code and some embedded SQL queries which contains all the data cleaning, analyses, visualizations and predictions.
