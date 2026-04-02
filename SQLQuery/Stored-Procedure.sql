CREATE PROCEDURE sp_InsertBuchung
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
@Kostennummer1 VARCHAR(50),

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
		select @ID = MAX(ID) from tblBuchungsdaten

        -- ?? 1. L?y t?n kho hi?n t?i theo v? trí
        Select @Lagerplatz = lp.Lagerplatz,@Lieferantnummer=lp.Lieferantnummer,@BestandAlt =lp.Bestand,
		@LagerplatzID=lp.ID,@Lager=lp.Lager,@Arbeitsplatz=lp.Arbeitsplatz,@Artikelzustand = lp.Artikelzustand
		From tblLagerPlatz lp left join tblGTMSCodes az on az.Code = lp.Artikelzustand
		where lp.Artikel = @Artikel and lp.Lagerort=@Lagerort and az.US=@ArtikelzustandTemp

        -- ?? 2. Tính t?n m?i, Station
        SET @BestandNeu = @BestandAlt + @Menge
		SET @Station ='ST10'

		Select @Bezeichnung1 = a.Bezeichnung1,@Bezeichnung2=a.Bezeichnung2,@Bezeichnung3=a.Bezeichnung3,@Preis1=al.Preis1,@Preis2=al.Preis2,@Preis3=al.Preis3,
		@Gruppe=a.Gruppe,@Artikeltyp=a.Artikeltyp,@Artikelhersteller=al.Artikelhersteller, @Artikelschnittstelle=al.Artikelschnittstelle
		from (select * from tblArtikel where Artikel = @Artikel) as a inner join tblArtikelLieferanten al on a.Artikel = al.Artikel 
		where @Artikelzustand=al.Artikelzustand

		SET @Kosten1 = @Menge*@Preis1
		SET @Kosten2 = @Menge*@Preis2
		SET @Kosten3 = @Menge*@Preis3

		Select @Personalnummer = Personalnummer from tblBenutzer where Benutzer = @Benutzer
		Set @Datum = FORMAT(GETDATE(),'yyyy-mm-dd hh:mm:ss tt')

		select * from tblKostenGruppen
		select @Kostengruppe1= kg.Kostengruppe from 
		(select * from tblKostenTraeger where Kostentraeger = @Kostentraeger1) ks inner join tblKostenGruppen kg on ks.KostenGruppenID = kg.GruppenID
		
		SET @Bemerkung = 'Goods Receipt by web external'

		
        -- ? Check âm kho
        IF (@BestandNeu < 0)
        BEGIN
            RAISERROR('Stock would be negative!', 16, 1);
        END

        -- ?? 3. T?ng t?n toàn h? th?ng
        SELECT @GesamtBestandAlt = ISNULL(SUM(Menge), 0)
        FROM tblBuchungsdaten
        WHERE Artikel = @Artikel;

        SET @GesamtBestandNeu = @GesamtBestandAlt + @Menge;
		select * from tblBuchungsdaten
        -- ?? 4. Insert d? li?u
        INSERT INTO tblBuchungsdaten (
		ID,Buchungscode,Arbeitsplatz,Station,Artikel,Materialnummer,Gruppe,Bereich,Bezeichnung1,Bezeichnung2,Bezeichnung3, Artikeltyp,
		Artikellieferant,Artikelhersteller,Artikelschnittstelle,Artikelzustand,Lieferantnummer,Charge,Serialnummer,Preis1,Preis2,Preis3,
		Menge,Mengeneinheit,Kosten1,Kosten2,Kosten3,Datum,Benutzer,Personalnummer,Abteilung,Kostenstelle,Lager,Lagerort,Lagerplatz,LagerplatzID,
		Kostengruppe1,Kostentraeger1,Kostennummer1,

         
        )
        VALUES (
            
        );

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;


select * from tblBuchungsdaten