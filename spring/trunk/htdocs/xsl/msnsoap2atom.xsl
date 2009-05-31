<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/"
                xmlns:msn="http://schemas.microsoft.com/MSNSearch/2005/09/fex"
                exclude-result-prefixes="msn soapenv">

  <xsl:output method="xml"/>

  <xsl:param name="searchTerms">cat</xsl:param>
  <xsl:param name="itemsPerPage">10</xsl:param>

  <xsl:template match="/soapenv:Envelope/soapenv:Body/msn:SearchResponse/msn:Response/msn:Responses/msn:SourceResponse">
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">
      <title type="text">Windows Live search for "<xsl:value-of select="translate( $searchTerms, '+', ' ' )" />" via Unto.net</title>
      <Query role="request"> 
        <xsl:param name="startIndex" select="msn:Offset + 1"/>
        <xsl:attribute name="startPage"><xsl:value-of select="floor( $startIndex div $itemsPerPage ) + 1"/></xsl:attribute> 
        <xsl:attribute name="searchTerms"><xsl:value-of select="$searchTerms"/></xsl:attribute>
      </Query>
      <opensearch:link rel="search"
         href="/spring/search/msn?format=description" type="application/opensearchdescription+xml"/>
      <opensearch:itemsPerPage><xsl:value-of select='$itemsPerPage'/></opensearch:itemsPerPage>
      <opensearch:totalResults><xsl:value-of select="msn:Total" /></opensearch:totalResults>
      <opensearch:startIndex><xsl:value-of select="msn:Offset + 1" /></opensearch:startIndex>
      <xsl:for-each select="msn:Results/msn:Result">
      <entry>
        <title><xsl:value-of select="msn:Title | msn:Url"/></title>
        <link><xsl:value-of select="msn:Url"/></link>
        <id><xsl:value-of select="msn:Url"/></id>
        <summary type="html"><xsl:value-of select="msn:Description"/></summary>
      </entry>
      </xsl:for-each>
    </feed>
  </xsl:template>

</xsl:stylesheet>

