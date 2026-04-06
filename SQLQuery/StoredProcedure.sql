CREATE OR ALTER PROCEDURE sp_InsertBuchung
    @Artikel VARCHAR(50),
    @Menge FLOAT,
    @Lagerort VARCHAR(50),
    @Benutzer VARCHAR(50),
	@ArtikelzustandTemp VARCHAR(50),
	@Kostentraeger1	VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE 
@ID INT,
@Buchungscode VARCHAR(50),
@Arbeitsplatz VARCHAR(50),
@Station VARCHAR(50),
@Materialnummer VARCHAR(100)='',
@Gruppe VARCHAR(50),
@Bereich VARCHAR(50)='',
@Bezeichnung1 NVARCHAR(255),
@Bezeichnung2 NVARCHAR(255),
@Bezeichnung3 NVARCHAR(255),
@Artikeltyp VARCHAR(50),
@Artikellieferant VARCHAR(100),
@Artikelhersteller VARCHAR(100),
@Artikelschnittstelle VARCHAR(100),
@Lieferantnummer VARCHAR(100),
@Charge VARCHAR(100)='',
@Serialnummer VARCHAR(100)='',
@Preis1 FLOAT,
@Preis2 FLOAT,
@Preis3 FLOAT,
@Mengeneinheit VARCHAR(20)='',
@Kosten1 FLOAT,
@Kosten2 FLOAT,
@Kosten3 FLOAT,
@Datum DATETIME,
@Personalnummer VARCHAR(50),
@Abteilung VARCHAR(50)='',
@Kostenstelle VARCHAR(50)='',
@Lager VARCHAR(50),
@Lagerplatz VARCHAR(50),
@LagerplatzID INT,

@Kostengruppe1 VARCHAR(50),
@Kostennummer1 VARCHAR(50)='',

@Kostengruppe2 VARCHAR(50)='',
@Kostentraeger2 VARCHAR(50)='',
@Kostennummer2 VARCHAR(50)='',

@Kostengruppe3 VARCHAR(50)='',
@Kostentraeger3 VARCHAR(50)='',
@Kostennummer3 VARCHAR(50)='',

@Kostengruppe4 VARCHAR(50)='',
@Kostentraeger4 VARCHAR(50)='',
@Kostennummer4 VARCHAR(50)='',

@Kostengruppe5 VARCHAR(50)='',
@Kostentraeger5 VARCHAR(50)='',
@Kostennummer5 VARCHAR(50)='',

@Kostengruppe6 VARCHAR(50)='',
@Kostentraeger6 VARCHAR(50)='',
@Kostennummer6 VARCHAR(50)='',

@Kostengruppe7 VARCHAR(50)='',
@Kostentraeger7 VARCHAR(50)='',
@Kostennummer7 VARCHAR(50)='',

@Kostengruppe8 VARCHAR(50)='',
@Kostentraeger8 VARCHAR(50)='',
@Kostennummer8 VARCHAR(50)='',

@Kostengruppe9 VARCHAR(50)='',
@Kostentraeger9 VARCHAR(50)='',
@Kostennummer9 VARCHAR(50)='',

@Kostengruppe10 VARCHAR(50)='',
@Kostentraeger10 VARCHAR(50)='',
@Kostennummer10 VARCHAR(50)='',

@BelegID VARCHAR(50)='',
@Serialnummerntext NVARCHAR(255)='',
@Serialnummernwert NVARCHAR(255)='',
@Serialnummerntext2 NVARCHAR(255)='',
@Serialnummernwert2 NVARCHAR(255)='',
@Bemerkung NVARCHAR(500),

@BestandAlt FLOAT,
@BestandNeu FLOAT,
@GesamtBestandAlt FLOAT,
@GesamtBestandNeu FLOAT,

@SchnittstelleFehlertext NVARCHAR(500)='',
@Artikelzustand NVARCHAR(255);

		SET @Buchungscode ='3001'
		select  @ID =MAX(ID) +1 from tblBuchungsdaten

		IF (@ID is NULL)
		BEGIN
			SET @ID =1
		END

        -- 1. Lấy tồn kho hiện tại theo vị trí
        Select @Lagerplatz = lp.Lagerplatz,@Lieferantnummer=lp.Lieferantnummer,@BestandAlt =lp.Bestand,
		@LagerplatzID=lp.ID,@Lager=lp.Lager,@Arbeitsplatz=lp.Arbeitsplatz,@Artikelzustand = lp.Artikelzustand
		From tblLagerPlatz lp left join tblGTMSCodes az on az.Code = lp.Artikelzustand
		where lp.Artikel = @Artikel and lp.Lagerort=@Lagerort and az.US=@ArtikelzustandTemp

        --  2. Tính tồn mới, Station
        SET @BestandNeu = @BestandAlt + @Menge
		SET @Station ='ST10'

		Select @Bezeichnung1 = a.Bezeichnung1,@Bezeichnung2=a.Bezeichnung2,@Bezeichnung3=a.Bezeichnung3,@Preis1=al.Preis1,@Preis2=al.Preis2,@Preis3=al.Preis3,
		@Gruppe=a.Gruppe,@Artikeltyp=a.Artikeltyp,@Artikelhersteller=al.Artikelhersteller, @Artikelschnittstelle=al.Artikelschnittstelle,@Artikellieferant=al.Artikellieferant
		from (select * from tblArtikel where Artikel = @Artikel) as a inner join tblArtikelLieferanten al on a.Artikel = al.Artikel 
		where @Artikelzustand=al.Artikelzustand

		SET @Kosten1 = @Menge*@Preis1
		SET @Kosten2 = @Menge*@Preis2
		SET @Kosten3 = @Menge*@Preis3

		Select @Personalnummer = Personalnummer from tblBenutzer where Benutzer = @Benutzer
		Set @Datum = GETDATE()

		select @Kostengruppe1= kg.Kostengruppe from 
		(select * from tblKostenTraeger where Kostentraeger = @Kostentraeger1) ks inner join tblKostenGruppen kg on ks.KostenGruppenID = kg.GruppenID
		
		SET @Bemerkung = 'Goods Receipt by web external'

		
        --  Check âm kho
        IF (@BestandNeu < 0)
        BEGIN
            RAISERROR('Stock would be negative!', 16, 1);
        END

        --  3. Tổng tồn toàn hệ thống
        SELECT @GesamtBestandAlt = ISNULL(SUM(Menge), 0)
        FROM tblBuchungsdaten
        WHERE Artikel = @Artikel;

        SET @GesamtBestandNeu = @GesamtBestandAlt + @Menge;
        -- 4. Insert dữ liệu

		update tblLagerPlatz SET Bestand = Bestand+@Menge 
		where Artikel=@Artikel and @Lagerplatz = @Lagerplatz and Artikelzustand = @Artikelzustand and @Artikeltyp = @Artikeltyp 
		and Lagerort = @Lagerort 

        INSERT INTO tblBuchungsdaten (
		ID,Buchungscode,Arbeitsplatz,Station,Artikel,Materialnummer,Gruppe,Bereich,Bezeichnung1,Bezeichnung2,Bezeichnung3, Artikeltyp,
		Artikellieferant,Artikelhersteller,Artikelschnittstelle,Artikelzustand,Lieferantnummer,Charge,Serialnummer,Preis1,Preis2,Preis3,
		Menge,Mengeneinheit,Kosten1,Kosten2,Kosten3,Datum,Benutzer,Personalnummer,Abteilung,Kostenstelle,Lager,Lagerort,Lagerplatz,LagerplatzID,
		Kostengruppe1,Kostentraeger1,Kostennummer1,Kostengruppe2,Kostentraeger2,Kostennummer2,Kostengruppe3,Kostentraeger3,Kostennummer3,
		Kostengruppe4,Kostentraeger4,Kostennummer4,Kostengruppe5,Kostentraeger5,Kostennummer5,Kostengruppe6,Kostentraeger6,Kostennummer6,
		Kostengruppe7,Kostentraeger7,Kostennummer7,Kostengruppe8,Kostentraeger8,Kostennummer8,Kostengruppe9,Kostentraeger9,Kostennummer9,
		Kostengruppe10,Kostentraeger10,Kostennummer10,BelegID,Serialnummerntext,Serialnummernwert,Serialnummerntext2,Serialnummernwert2,
		Bemerkung,BestandAlt,BestandNeu,GesamtBestandAlt,GesamtBestandNeu,SchnittstelleFehlertext)
        VALUES (
		@ID,@Buchungscode,@Arbeitsplatz,@Station,@Artikel,@Materialnummer,@Gruppe,@Bereich,@Bezeichnung1,@Bezeichnung2,@Bezeichnung3, @Artikeltyp,
		@Artikellieferant,@Artikelhersteller,@Artikelschnittstelle,@Artikelzustand,@Lieferantnummer,@Charge,@Serialnummer,@Preis1,@Preis2,@Preis3,
		@Menge,@Mengeneinheit,@Kosten1,@Kosten2,@Kosten3,@Datum,@Benutzer,@Personalnummer,@Abteilung,@Kostenstelle,@Lager,@Lagerort,@Lagerplatz,@LagerplatzID,
		@Kostengruppe1,@Kostentraeger1,@Kostennummer1,@Kostengruppe2,@Kostentraeger2,@Kostennummer2,@Kostengruppe3,@Kostentraeger3,@Kostennummer3,
		@Kostengruppe4,@Kostentraeger4,@Kostennummer4,@Kostengruppe5,@Kostentraeger5,@Kostennummer5,@Kostengruppe6,@Kostentraeger6,@Kostennummer6,
		@Kostengruppe7,@Kostentraeger7,@Kostennummer7,@Kostengruppe8,@Kostentraeger8,@Kostennummer8,@Kostengruppe9,@Kostentraeger9,@Kostennummer9,
		@Kostengruppe10,@Kostentraeger10,@Kostennummer10,@BelegID,@Serialnummerntext,@Serialnummernwert,@Serialnummerntext2,@Serialnummernwert2,
		@Bemerkung,@BestandAlt,@BestandNeu,@GesamtBestandAlt,@GesamtBestandNeu,@SchnittstelleFehlertext
        );

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;

EXEC sp_InsertBuchung
    @Artikel = '0509253',
    @Menge = 10,
    @Lagerort = 'TM226',
    @Benutzer = 'Admin',
    @ArtikelzustandTemp = 'Reworked',
    @Kostentraeger1 = 'A2 2.5 C-HSG';

select * from tblBuchungsdaten

DELETE FROM tblBuchungsdaten;


go
CREATE PROCEDURE sp_GetArtikeltoGoodsReceipts
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        LTRIM(RTRIM(Artikel)) AS Artikel,
        LTRIM(RTRIM(az.US)) AS Artikelzustand,
        LTRIM(RTRIM(Lagerort)) AS Lagerort,
        LTRIM(RTRIM(kg.Kostengruppe)) AS Kostengruppe,
        LTRIM(RTRIM(kz.Kostentraeger)) AS Kostentraeger
    FROM tblLagerPlatz lp
    INNER JOIN tblGTMSCodes az 
        ON az.Code = lp.Artikelzustand 
    INNER JOIN tblKostenArtikel ka 
        ON ka.Wert = lp.Artikel 
    INNER JOIN tblKostenGruppen kg 
        ON ka.KostenGruppenID = kg.GruppenID
    INNER JOIN tblKostenZuordnung kz 
        ON kz.FolgeKostenGruppenID = kg.GruppenID
    WHERE lp.Artikel <> ''
    GROUP BY 
        Artikel, 
        az.US, 
        Lagerort, 
        kg.Kostengruppe, 
        kz.Kostentraeger;
END;

CREATE TABLE tblAccountExternalWeb (
    ID INT PRIMARY KEY IDENTITY(1,1),

    Username NVARCHAR(50) NOT NULL,

    PasswordHash NVARCHAR(255) NOT NULL,

    Alias NVARCHAR(50) NULL,

    CreatedAt DATETIME NULL
);