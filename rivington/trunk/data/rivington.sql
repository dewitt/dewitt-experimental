-- MySQL dump 8.23
--
-- Host: localhost    Database: rivington
---------------------------------------------------------
-- Server version	3.23.58

--
-- Table structure for table `urls`
--

CREATE TABLE urls (
  url text NOT NULL,
  id mediumint(9) NOT NULL auto_increment,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Dumping data for table `urls`
--


INSERT INTO urls VALUES ('http://www.unto.net/',1);

