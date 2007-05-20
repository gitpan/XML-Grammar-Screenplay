<xsl:stylesheet version = '1.0'
     xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//W3C//DTD XHTML 1.1//EN"
 doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
 />

<xsl:template match="/">
        <xsl:apply-templates select="//body" />  
</xsl:template>

<xsl:template match="body">
    <html>
        <head>
            <title>My Screenplay</title>
        </head>
        <body>
            <div class="screenplay">
            <xsl:attribute name="id">
                <xsl:value-of select="@id" />
            </xsl:attribute>
            <xsl:apply-templates select="scene" />
            </div>
        </body>
    </html>
</xsl:template>

<xsl:template match="scene">
    <div class="scene" id="scene-{@id}">
        <!-- Make the title the title attribute or "ID" if does not exist. -->
        <xsl:element name="h{count(ancestor-or-self::scene)}">
            <xsl:attribute name="id">
                <xsl:value-of select="@id" />
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@title">
                    <xsl:value-of select="@title" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@id" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
        <xsl:apply-templates select="scene|description|saying" />
    </div>
</xsl:template>

<xsl:template match="description">
    <div class="description">
        <xsl:apply-templates />
    </div>
</xsl:template>

<xsl:template match="saying">
    <div class="saying">
        <xsl:apply-templates />
    </div>
</xsl:template>

<xsl:template match="para">
    <p>
        <xsl:if test="local-name(..) = 'saying'">
            <strong class="saying"><xsl:value-of select="../@character" />: </strong>
        </xsl:if>
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=1] = .">
            [
        </xsl:if>
        <xsl:apply-templates />
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=last()] = .">
            ]
        </xsl:if>
    </p>
</xsl:template>

<xsl:template match="ulink">
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="@url" />
        </xsl:attribute>
        <xsl:apply-templates />
    </a>
</xsl:template>

<xsl:template match="bold">
    <strong class="bold">
        <xsl:apply-templates />
    </strong>
</xsl:template>

<xsl:template match="inlinedesc">
    <span class="inlinedesc">[<xsl:apply-templates />]</span>
</xsl:template>

</xsl:stylesheet>
