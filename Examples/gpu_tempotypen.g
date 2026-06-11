

#template raylib
//#template console
#include graphics_defines1280x720.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library raylib raylib.dll
#library soloud soloud_x64.dll
#library mikmod libmikmod-3.dll


class ScrollCharacter {
    raylib_Vector2 position;
    bool visible;
    u8 theChar;

    function Init() {
        this.theChar = 'a';
        this.visible = false;
        this.position.x = 0.0f;
        this.position.y = 340.0f;
    }

    function MoveLeft() {
        this.position.x = this.position.x - 3.0f;
    }

    function CheckBounds() {
        if (this.position.x < 160.0f) {
            this.visible = false;
        }
    }
}


#define NR_LETTERS 35
ScrollCharacter[NR_LETTERS] scrollChars = [];
int scrollTextNeedle = 0;
byte* scrollText = `      Waarom de Commodore Amiga en Atari ST verloren...      \
Vlak voor de zomer van 1985 kochten we een Commodore 64. De machine had een MOS-6510 geklokt op 1 MHZ. Drie jaar lang hebben we er veel plezier aan beleeft, vooral door de \
grote software collectie. Het spel Commando was net uitgekomen en die bevatte de legendarische chiptune van Rob Hubbard. Een aantal maanden later kwam Rambo uit, dat \
overigens meer hype dan speelbaarheid was. Het wachten tijdens het inladen van de spellen begon te vervelen, dus kochten we een externe C-1541 diskdrive. Dat bracht iets \
verbetering, maar nog steeds duurde het inladen zeer lang. Tevens kochten we een Power Cartridge en later een Expert Cartridge. Hierdoor konden we makkelijk experimenteren \
met machinecode. Het pauzeren van een draaiend spel om een font in het geheugen te zoeken was leuk. De C64 had een ingebouwde Basic. Die was traag, maar geschikt om te \
leren programmeren. Top!       \
Drie jaar later, in maart 1988, kochten we een tweedehands Amiga 500 met 1.2 kickstart. Wat een vooruitgang! 4 kanaals 8-bit stereo via Direct Memory Access, 512k geheugen, \
een 7 MHZ 68000 processor en parallel werkende custom chips. De belangrijkste custom chip, de Agnus, had een blocktransfer en video-synchronized coprocessor subcomponent \
(Blitter en Copper). Alweer top!       \
We waren zo enthousiast dat m'n broer eind 1988 een tweede Amiga erbij kocht. De hardware was hetzelfde, maar door de kickstart 1.3 werkten een klein aantal spellen niet meer. \
Tevens werd een Citizen 120D naaldprinter en een externe 5,25" diskdrive aangeschaft. Het geheugen van beide Amiga's werd uitgebreid tot 1 megabyte om diskettes in 1 keer te \
kunnen kopieeren. De 1.3 Amiga had 1 Mb chipram, maar de software vereiste dat nooit.       \
De introductie van de Amiga 1000 desktop had al in juli 1985 plaatsgevonden. Dat was een maand later dan de introductie van de Atari 520ST in juni 1985. Die had ook een 68000, \
maar dan op 8 MHZ geklokt. De Atari ST had geen Blitter of Copper en de geluidschip had slechts 3 analoge kanalen. De Amiga was beter in beeld en geluid. De Amiga kon 32 kleuren \
uit een palette van 4096 in games tonen, terwijl de Atari ST door z'n vaste 32k schermbuffer er maar 16 kon laten zien. Dat is een groot verschil, want bij 16 kleuren heb je het \
C-64 gevoel, maar bij 32 kleuren krijg je het Arcade speelhal gevoel. De prijs van de Atari ST was wel lager.      \
Dat was 1985. Vervolgens heeft Commodore het voor elkaar gekregen om ZEVEN JAAR LANG geen nieuwe generatie van de Amiga uit te brengen. Pas op 21 oktober 1992 kwam de Amiga 1200 \
met de AGA chipset uit, die je als opvolger van de Amiga 500 kunt zien.      \
Realiseer je je even hoe lang 7 jaar was in die begintijd! Ongelovelijk lang!      \
Ik weet nog dat ik begin 1991 dacht: waar is die opvolger van de Amiga 500? Ik had de machine al bijna 3 jaar. Je toetsenbord wordt vies, je muis wordt slechter, je bent toe aan \
een nieuw systeem. Er was een jongen die ik kende en die heeft in juni '92 een nieuwe Amiga 600 gekocht omdat hij toe was aan een "verse" Amiga. Dat model had echter dezelfde \
hardware! Je gaat toch niet twee keer dezelfde computer kopen? Voor de business markt had Commodore de Amiga 3000 uitgebracht in 1990, maar die kostte een fortuin. Die was \
niet "for the masses" en daarom geen opvolger van de Amiga 500. In 1991 werd het mij steeds duidelijker dat Commodore de Amiga community in de steek had gelaten en dat al jaren.      \
In 1992, toen eindelijk de nieuwe Amiga 1200 bekend werd gemaakt, waren de specificaties tegenvallend. Het had een trage 14 MHZ processor uit 1984 aan boord en 2 MB aan memory. \
Bedenk even dat een mid-range PC in 1992 een 486 met 33 MHZ en 4 MB memory had. Tevens een harddisk.      \
Dat de PC de Amiga aan het inhalen was, werd mij in september 1991 al duidelijk, toen ik naar de HTSA ging. De school had PC/AT systemen met 16 MHZ en een harddisk. Grafische \
mogelijkheden en geluid liepen echter achter t.o.v. de Amiga en daarom stelde ik de aankoop van een nieuw systeem gewoon uit.      \
Toen ik in september 1994 de studie weer opnieuw oppakte, was de situatie helemaal duidelijk geworden. Er stonden Intel 80486SX systemen met 25 of 33 MHZ en VGA op school. \
Het was de periode van de DX4 100 MHZ processors en die zijn niet meer te vergelijken met een Amiga 1200 op 14 MHZ. Ik kocht een nieuwe ESCOM DX2-66 met 4 mb geheugen en 420 mb \
harddisk en kleuren monitor. Achteraf gezien een goed systeem voor fl 2099,- Daarmee kon ik Windows 3.1, MS-Word en MS-Excel draaien. Ook bleek ik DOOM 2 te kunnen draaien die \
een aantal maanden later uitkwam. Eerder in 1994 was Commodore failliet gegaan. De PC had gewonnen. Die was sneller, goedkoper en uitbreidbaar. Nooit meer zeven jaar wachten op \
een nieuw systeem. Bij een PC kon je ieder jaar iets beters kopen.      \
Wat mij achteraf pas duidelijk is geworden, is hoe weinig focus Commodore had op de Amiga. Je kunt bijvoorbeeld in nr. 7 van Commodore Info uit 1985 lezen over de Commodore PC-10, \
dat was een IBM PC clone met DOS, over de Commodore 900 machine met UNIX, over de Amiga en natuurlijk de Commodore 64 en VIC-20. Een aantal nummers eerder kon je lezen over de \
CP/M modus van de C-128. Die techneuten van Commodore deden alles tegelijkertijd!      \
In 1990 was Commodore bezig de PC-60-III uit te brengen voor hun Commodore PC clone lijn, tevens bezig met een nieuw marktsegment in de vorm van de CD gebaseerde CDTV en ook bezig \
met de C-65, de 8-bit opvolger van de C-64. Voor die C-65 hadden ze speciaal de CSG-4510 processor ontworpen op 3,5 MHZ, tevens de VIC-III chip met een 320x200 256 kleuren mode \
en een DMA controller met blitter. De C-65 had ook twee SID chips, 128K RAM en 128K ROM. Ze waren dat systeem aan het ontwerpen en bouwen terwijl ze de Amiga al 5 jaar hadden. \
Ongelovelijk. Wat een verspilling van tijd en geld.      \
Dan komen we nu bij de crux van dit verhaal.      \
Het wordt pas echt ongelovelijk als je hoort dat Jay Miner, de oorspronkelijke ontwerper van de Amiga, al in 1987 de prototypes klaar had van de volgende Amiga generatie: De Amiga \
Ranger. Deze Ranger kon 128 kleuren weergeven op een 1024x1024 display en kon 2MB chipram aansturen. Het was een waardige concurrent geweest van de Apple Macintosh II die in \
1987 uitkwam.      \
Jay Miner vertrok in 1988 toen het Amiga team grotendeels uitgehold was. Er waren verschillende werkende prototypes van Amiga Ranger bij Commodore op dat moment. In een Amiga \
club bijeenkomst uit 1990 kun je horen hoeveel ideeën Jay Miner had om de Amiga verder te krijgen. Een verdubbeling van de snelheid was sowieso mogelijk volgens hem. Om zo'n \
gemotiveerde, kundige chipontwerper niet te benutten en ook nog eens z'n werk te laten verstoffen is echt zonde.      \
Als je Jay Miner hoort praten in 1990, dan hoor je hem steeds de slechte marketing van de Amiga naar voren brengen. In Amerika wist het publiek nauwelijks af van het bestaan van \
de Amiga. De TV commercials die door Commodore gemaakt werden waren zo slecht dat niemand wist wat de mogelijkheden van de Amiga waren. Het resultaat was dat er maar 650.000 \
Amiga's in Amerika zijn verkocht over de totale looptijd. Dat is schikbarend weinig voor de grootste afzetmarkt en thuisland van Commodore. In Engeland werden er 1.500.000 \
Amiga's verkocht!      \
De marketing afdeling in Amerika faalde echt. Het publiek wist niet wat ze concreet konden verwachten van de computer. Die informatie werd nooit gegeven in een commercial, \
alleen maar dat de Amiga al je dromen kon waarmaken en je er alles mee kon. Dat soort pocherige loze woorden maakten terecht geen indruk bij het grote publiek.      \
Zo moeilijk had de marketing afdeling het overigens niet. Van 1985 tot 1990 was de Amiga ver z'n tijd vooruit. Er was geen enkele computer die zo veel mogelijkheden had en \
betaalbaar was. Tevens kende de doelgroep reeds de Commodore 64, de veelverkochte voorganger van de Amiga 500. Er waren in 1988 maar liefst 7 miljoen Commodore 64 machines in \
Amerika in gebruik, daar had de marketing afdeling gebruik van kunnen maken, maar nee, Commodore maakte een reclame waarin een oude man langzaam een ladder opklimt, een stuk \
loopt en achter een lichtende computer gaat zitten. Dat duurt bij elkaar een minuut. Vervolgens is de reclame voorbij.      \
De reden voor alle onkunde was simpel: er was geen management met een passie voor computers, zoals bij Apple. Hoe kon Commodore dan zo'n topproduct als de Amiga ontwikkeld \
hebben? Nou, dat hebben ze dan ook niet! De Amiga chipset en technologie was ontwikkeld door het bedrijf Amiga onder leiding van Jay Miner, de engineer van de Atari 2600, \
Atari 400 en Atari 800. Oorspronkelijk zou de Amiga een game console worden, maar door de video-game crash van 1983 leek het meer opportuun om een desktop computer te maken. \
Deze historie verklaart waarom de Amiga geen Basic had bij het opstarten en geen characterset graphics (beide een gemis, naar mijn mening). De Amiga was geen voortzetting van \
de C64. Commodore had het bedrijf Amiga in Augustus 1984 gekocht voor 27 miljoen dollar. In zekere zin was Amiga de redder van Commodore, want anders waren ze eerder failliet \
gegaan. In 1990 verkocht Commodore 750.000 Amiga's en in 1991 zelfs meer dan een miljoen. Atari verkocht 300.000 Atari ST's in 1990.      \
Een gezamelijke hobbel voor Commodore en Atari was het feit dat Motorola processors duur waren. Atari had in 1990 de Atari TT030 uitgebracht met een 68030, maar die kostte \
3000 dollar (5400 gulden) bij de introductie. Zo'n bedrag lag buiten het budget van de normale thuisgebruiker. Door de hoge prijs werden er weinig machines verkocht en daardoor \
lieten software ontwikkelaars het systeem links liggen. Een vicieuze cirkel.      \
Toch waren er meer optie's: Hitachi was een second-source van de 68k en had met de 68HC000 een CMOS versie uitgebracht van de 68k uitgebracht in 1985. Deze liep op 20 MHZ en \
gebruikte veel minder stroom. Commodore had deze chip kunnen inzetten.      \
De grote "splash" waar iedere Amiga en Atari gebruiker eind 1990 op hoopte, namelijk een goedkoop 68030 25 MHZ systeem, kwam er niet. Waarschijnlijk had Commodore zo'n systeem \
niet eens kunnen ontwikkelen vanwege hun oplopende achterstand qua chip procedee.      \
IBM had vanaf het begin van hun PC-lijn in 1980 besloten dat er meerdere fabrikanten van de processor moesten zijn. In 1982 werd AMD getekend als tweede fabrikant van de x86. \
Concurrentie zorgt voor prijsdalingen. In 1990 werden er 16,8 miljoen PC's verkocht. Als je een nieuwe PC kocht, dan kon je veel oude software nog draaien op je nieuwe systeem. \
Dat is prettig en haalt onzekerheid weg bij consumenten die een nieuw systeem willen aanschaffen.      \
Eind 1992 kwamen dus Commodore en Atari met hun nieuwe computers aanzetten: De Amiga 1200 (14 MHZ) en de Atari Falcon030 (16 MHZ). Allebei weer met een Motorola processor. \
Als Commodore echt ontevreden was over de prijsstelling of de snelheid van de Motorola, dan hadden ze een andere chip kunnen kiezen. Apple heeft vaak gewisseld van processor \
architectuur.      \
In 1992 werd het duidelijk dat de wijze waarop Commodore chips maakte gedateerd was. Ze konden de graphics chip en de bus-controller chip van de Amiga 1200 niet meer zelf maken. \
Dat werd uitbesteed aan HP en VLSI. Het voordeel van een eigen chipfabriek was er niet meer.      \
Commodore was nu afhankelijk van andere partijen en door een inschattingsfout bij het bestellen van de chips bij andere partijen waren er in december 1992 geen Amiga 1200's \
meer te krijgen. De magazijnen lagen wel vol met Amiga 600's maar die computers met 7 jaar oude technologie wilde niemand voor de volle prijs. De Amiga 600 was een idee \
geweest van de ingehuurde Mehdi Ali, die net als Irving Gould een miljoenen jaarsalaris opstreek, maar geen resultaten neerzette. Tevens holde Mehdi Ali de R&D teams uit.      \
Atari maakte grote marketing fouten door de Falcon neer te zetten als een business machine en in het nieuws brengen dat er een Falcon040 op basis van de 68040 32 MHZ in 1993 \
zou verschijnen. De oude Atari ST voorraad werd in 1993 gedumpt, waardoor de Falcon duur leek. Na de dumping werd de Atari ST lijn in 1993 gestopt. Door de slechte verkopen \
en de slechte financiële situatie stopte Atari eind 1993 met de Falcon030 en ging zich volledig richten op de Jaguar 64 game console, die overigens ook geen succes werd.      \
Commodore verkocht weinig in 1993. Iedereen kocht een PC om Windows 3.1 te kunnen draaien. Dat jaar werden er 27 miljoen PC's verkocht en 155 duizend Amiga's. Dat is 175 \
keer meer PC's dan Amiga's. Dan heeft de markt gesproken.      \
In 1982 had Commodore de leiding qua computer innovatie met hun eigen 6502 processor, chipfabriek en computers. In 1994 was hun chip procedee achterhaald en hadden ze hun \
R&D teams uitgehold. Tevens was het management al jaren bezig geweest met het verrijken van zichzelf door hoge salarissen uit te keren zonder tegenprestatie. Het einde kon \
niet uitblijven op zo'n manier. In die laatste tijd is het project Hombre kenmerkend. Dat was geen ontwikkeling meer vanuit hun eigen chipfabriek, maar gebaseerd op \
Hewlett-Packards PA-RISC architectuur. Tevens wilde project Hombre compatibel zijn met Windows NT.      \
Het faillissement van Commodore op 6 mei 1994 was onafwendbaar. Na een jaar kwam het nieuws dat ESCOM het merk Commodore had overgenomen en wellicht nog Amiga's ging \
verkopen. Het was een poging van ESCOM om te differentiëren omdat ze veel fysieke PC-winkels hadden maar de constante prijsverlagingen van PC onderdelen niet konden bijbenen. \
In 1995 boekte ESCOM een verlies van 185 miljoen DM, wat natuurlijk niets met de overname van Commodore te maken had. In 1996 ging ESCOM failliet.      \
Tegenwoordig is Commodore allang legacy. Kijk uit met het kopen van een oude Commodore 64, want veel MOS IC's en RAM chips zijn of gaan kapot en de voeding bevat geen \
voltage beveiliging. Als de condensatoren uitgedroogd zijn dan worden je chips gefrituurd door teveel voltage. Ook latere modellen hadden hier last van. "Bricks-of-death" worden \
ze genoemd omdat ze gevuld zijn met Epoxy. Dat was een methode om te voorkomen dat de goedkope voeding in de fik vloog. Door de slechte kwaliteit was het geen toeval dat onze \
voeding toendertijd ook kapot ging. We hebben toen een alternatieve voeding uit Duitsland gekocht. Verder droogt de gebruikte koeling-pasta op waardoor de chips te heet worden \
in oude machines. Veel C-1541 diskdrives krijgen ook problemen, als je een draaiknop aan de voorkant hebt dan zit er waarschijnlijk een Mitsumi binnenwerk in en daar trekt \
uiteindelijk vocht in de spoelen die daardoor kortsluiting veroorzaakt. C-64's zijn leuke machines om te repareren, want Commodore monteerde in hun machines maar net wat ze \
voor handen hadden, dus veel machines zijn verschillend. Zo zijn er machines die een oude bios kregen. Sommige C-64's hadden sockets omdat bepaalde chips niet voorradig waren \
en er later ingedrukt werden. Met een oude C64 kun je beter wat electronica kennis hebben, want er gaat nog wel eens wat kapot. Wat een enorm verschil met de \
japanse NEC PC-8001 uit 1981. Die werkt 43 jaar later gewoon nog steeds.      \
Het romantiseren van het bedrijf Commodore is iets dat ik niet doe. Veel mooie ontwikkelingen kwamen namelijk niet uit hun eigen gelederen. De MOS 6502 was niet door Commodore \
zelf ontwikkeld en de Amiga ook niet. De SID en VIC-II chip van de Commodore 64 wel, maar de engineers daarvan kregen geen bonus of credits voor hun uitstekende werk, terwijl de \
koers van Commodore enorm was gestegen. Daardoor namen de ontwerpers van de SID en VIC-II, Yannes en Charpentier al in september 1982 ontslag. Chuck Peddle, de ontwerper van de \
6502 en de Commodore PET was al in 1980 voor de tweede keer vertrokken.      \
De verhalen van Bill Herd geven een indruk hoe het eraan toeging bij Commodore. Bill had strakke deadlines gekregen en deed vreemde workarounds, zoals teveel voltage gebruiken \
of een lijntje over het moederbord leggen, of de Z80 gebruiken om de C64-mode op te starten. De C-128 had een twee keer zo snelle CPU, maar had in die mode geen 40-kolom video \
output, waardoor de C-128 basic dus langzamer was dan die van de C-64.      \
Vervolgens de hele faal rond de Commodore 264-series en z'n prijsbeleid, waardoor alle machines in die serie faalden, namelijk de C-16, C-116 en de Plus/4. Die computers hadden \
een "TED" chip zonder sprites en scrolling, maar de prijzen waren bijna gelijk aan die van de C-64. Gelukkig waren wij vroeger thuis verstandig genoeg om de Plus/4 niet te \
kopen, maar wellicht zijn er andere mensen wel ingetrapt.      \
Als klap op de vuurpijl veronachtzaamden ze bij Commodore ook nog hun reddingsboei Amiga en z'n maker Jay Miner.      \
Volgens mij had Commodore een goede gebruikerservaring niet op nr. 1 staan. Een voorbeeld: het was bekend dat de C-64 een hele trage tape datasset had, namelijk 50 bytes \
per seconde. Toen ze rond 1984 de C-116 uitbrachten, zou je denken dat ze dit probleem wel opgelost hadden. Maar nee, nog steeds de oude snelheid van 50 bytes per seconde. \
Dan duurt het inladen van 16k ongeveer 6 minuten. Ook de C-1541 diskdrive was traag. Ongeveer 350 bytes per seconde. Dat kwam omdat Commodore overging van parallele \
communicatie naar seriele communicatie om kosten te besparen met gelijkblijvende winstmarges. De eerdere Commodore 2040 PET diskdrive van 1979 was 5 keer sneller en kon \
1706 bytes per seconde binnenhalen. Echt waar!      \
Dus geen oude Commodore 64 of Amiga voor mij. Het klik-geluid van de Amiga diskdrive wil ik niet meer aanhoren. Daar koos Commodore voor omdat ze de goedkoopste discdrives \
wilden gebruiken. Bij de Amiga 1200 deed Commodore overigens weer goedkoop, want de trage 14 MHZ processor schijnt een dump partij van Motorola te zijn geweest.      \
Tevens vind ik het verschil tussen NTSC en PAL hinderlijk. De Amerikaanse C64's en Amiga's draaiden op NTSC en hadden 240 rasterlijnen met een refresh van 60 Hertz. De 
europese C64's hadden 288 rasterlijnen op 50hz, waardoor de PAL machine's 48 meer rasterlijnen hadden tijdens vertical blank. Dit betekende dat een PAL machine per frame meer \
rekentijd had. Dat kon gevolgen hebben voor de speelbaarheid van spellen. De Amiga had in 60hz NTSC gebieden een resolutie van 320x200 en in 50hz PAL gebieden een beeld \
van 320x256. AmigaDOS hield daar standaard geen rekening mee en het window was dus altijd te klein bij PAL machines.      \
Een oude Windows PC roept bij mij veel positievere gevoelens op. Dat systeem is altijd uitbreidbaar en betaalbaar geweest. De Amiga bal muis kostte lange tijd 139 gulden. \
In '91: 119 gulden. In '93: 98 gulden. Toen ik in '94 een PC kocht, kostte m'n nieuwe muis 15 gulden. Het was een schok, want die muis was beter. Dat prijsverschil heeft een \
enorme afkeer voor Commodore bij mij teweeg gebracht en een respect voor de PC. Inmiddels gebruik ik al 30 jaar een x86 Windows PC. Reeds 12 keer heb ik een nieuwe PC \
gekocht op een moment dat het mij goed uitkwam, en iedere nieuwe PC was beter dan de vorige. De laatste 10 jaar heb ik geen noemenswaardige software probleem gehad door een \
nieuw aangeschafte Windows PC. Het systeem is compatible. Top!      \
Als het bovenstaande verhaal gelezen hebt, dan weet je dat ik me nooit ga bezighouden met Retro zaken rond Commodore.                        `;


function GetNewScrollLetter() : u8 {
	u8 c = scrollText[scrollTextNeedle];
    c = msvcrt.tolower(c);
	scrollTextNeedle++;
	if (scrollText[scrollTextNeedle] == 0)
		scrollTextNeedle = 0;
	return c;
}


/*   Precalculation   */
int* fontXOffsets = msvcrt.calloc(sizeof(int), 256);
int* fontYOffsets = msvcrt.calloc(sizeof(int), 256);
function setupFontOffsetsLine(string fontString, int offsetY) {
	for (i in 0..7) {
		fontXOffsets[fontString[i]] = i * 40;
		fontYOffsets[fontString[i]] = offsetY;
	}
}
setupFontOffsetsLine("abcdefgh", 0);
setupFontOffsetsLine("ijklmnop", 1*41);
setupFontOffsetsLine("qrstuvwx", 2*41);
setupFontOffsetsLine(`yz!"#$'(`, 3*41);
setupFontOffsetsLine(").+,-/01", 4*41);
setupFontOffsetsLine("23456789", 5*41);
setupFontOffsetsLine(";>=<? !@", 6*41);
setupFontOffsetsLine("ABCDEFGH", 0);
setupFontOffsetsLine("IJKLMNOP", 1*41);
setupFontOffsetsLine("QRSTUVWX", 2*41);
setupFontOffsetsLine(`YZ!"#$'(`, 3*41);



byte* vertexShader = `
#version 330
in vec3 vertexPosition;
in vec2 vertexTexCoord;
out vec2 fragTexCoord;
uniform mat4 mvp;
void main()
{
    fragTexCoord = vertexTexCoord;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}
`;



byte* fragmentShader = `
#version 330
in vec2 fragTexCoord;
out vec4 fragColor;
uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D texture0;
uniform vec2 iPoints[4];
uniform vec2 explosion;
uniform float explosionTime;

vec2 Hash12(float t) {
    float x = fract(sin(t*674.3) * 453.2);
    float y = fract(sin((t+x)*714.3) * 263.2);
    return vec2(x,y);
}

#define NUM_LAYERS 3.
#define TAU 6.28318
#define PI 3.141592
#define Velocity .010 //modified value to increse or decrease speed, negative value travel backwards
#define StarGlow 0.025
#define StarSize 02.
#define CanvasView 20.

float Star(vec2 uv, float flare){
    float d = length(uv);
  	float m = sin(StarGlow*1.2)/d;  
    float rays = max(0., .5-abs(uv.x*uv.y*1000.)); 
    m += (rays*flare)*2.;
    m *= smoothstep(1., .1, d);
    return m;
}

float Hash21(vec2 p){
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p+45.32);
    return fract(p.x*p.y);
}

vec3 StarLayer(vec2 uv){
    vec3 col = vec3(0);
    vec2 gv = fract(uv);
    vec2 id = floor(uv);
    for(int y=-1;y<=1;y++){
        for(int x=-1; x<=1; x++){
            vec2 offs = vec2(x,y);
            float n = Hash21(id+offs);
            float size = fract(n);
            float star = Star(gv-offs-vec2(n, fract(n*34.))+.5, smoothstep(.1,.9,size)*.46);
            vec3 color = sin(vec3(.2,.2,.2)*fract(n*2345.2)*TAU)*.25+.75;
            color = color*vec3(0.9,0.9,0.9+size);
            star *= sin(iTime*.6+n*TAU)*.5+.5;
            col += star*size*color;
        }
    }
    return col;
}

float random3_1(vec3 point) 
{
    return fract(sin(dot(point, vec3(12.9898,78.233,45.5432)))*43758.5453123);
}

float thunder(vec2 uv, float time, float seed, float segments, float amplitude)
{
    float h = uv.x+0.3;
    float s = uv.y*segments;
    float t = time*20.0;
    
    vec2 fst = floor(vec2(s,t));
    vec2 cst = ceil(vec2(s,t));
    
    float h11 = h + (random3_1(vec3(fst.x, fst.y, seed)) - 0.5) * amplitude;
    float h12 = h + (random3_1(vec3(cst.x, fst.y, seed)) - 0.5) * amplitude;
    float h21 = h + (random3_1(vec3(fst.x, cst.y, seed)) - 0.5) * amplitude;
    float h22 = h + (random3_1(vec3(cst.x, cst.y, seed)) - 0.5) * amplitude;
    
    float h1 = mix(h11, h12, fract(s));
    float h2 = mix(h21, h22, fract(s));
    float alpha = mix(h1, h2, fract(t));
    
    return 1.0 - abs(alpha - 0.5) / 0.5;
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 center = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 frontUV = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
    vec2 backUV = frontUV;

    vec2 point = iPoints[0];
    vec2 pointCenter = (fragCoord - point) / iResolution.y;
    vec2 explosionCenter = (fragCoord - explosion) / iResolution.y;

    float wave = sin(frontUV.x * 3.0 + iTime * 3.0) * 0.10 + (sin(frontUV.x * -7.0 + iTime * -2.0) * 0.10);
    frontUV.y += wave;

    pointCenter.y += wave;
    explosionCenter.y += wave;

    vec4 col2 = vec4(0.0);
    if (point != vec2(0.0,0.0))
    {
        vec3 col = vec3(0.0);
        float d = length(pointCenter);
        float mask2 = step(0.038, d); 
        col += 0.010/d;
        col *= mask2;
        col2 = vec4(col, 1.0); //step(0.9, col)); //step(0.1, col));
    }

    //Explosion
    vec4 expColor = vec4(0.0);
    if (explosion != vec2(0.0, 0.0))
    {
        float explVerschil = iTime - explosionTime;
        if (explVerschil < 0.8f) {

            //vec3 tmpCol = vec3(0.0);
            float tmpCol = 0.0;
            for (float i=0.;i<8;i++) {
                vec2 dir = Hash12(explosionTime+i)-0.5;
                //float t = fract(explVerschil);
                float d = length(explosionCenter+(dir*explVerschil*2.8));
                tmpCol += 0.02/d;
                tmpCol *= 1.0-(explVerschil*2.0);
                expColor = vec4(tmpCol, tmpCol, tmpCol, 1.0);
            }
        }
    }

    //Bliksem
    vec2 uvBliksem = gl_FragCoord.xy / iResolution.y;
    float bliksemAlpha = 0.0;
    for(int i = 0; i < 3; ++i)
    {
        float f = float(i) + 0.0;
        float a = thunder(uvBliksem, iTime, f, 10.0 * pow(1.25, f), 0.125 * pow(1.25, f));
        a = pow(a, f + 2.0); 
        bliksemAlpha = max(bliksemAlpha, a);
    }
    bliksemAlpha = max((bliksemAlpha-0.9)/0.1, 0.0);
    vec4 bliksemColor = vec4(bliksemAlpha, bliksemAlpha, bliksemAlpha, 1.0);

    // stars
    vec4 starsColor = vec4(0.0);
    vec2 uv3 = (fragCoord -.5 * iResolution.xy) / iResolution.y;
	vec2 M = vec2(0);
    //M -= vec2(M.x+sin(iTime*0.22), M.y-cos(iTime*0.22));
    float t = iTime*Velocity; 
    vec3 col = vec3(0);  
    for(float i=0.; i<1.; i+=1./NUM_LAYERS){
        float depth = fract(i+t);
        float scale = mix(CanvasView, .5, depth);
        float fade = depth*smoothstep(1.,.9,depth);
        col += StarLayer(uv3*scale+i*453.2-iTime*.05+M)*fade;}   
    starsColor = vec4(col,1.0);


    vec2 ndc = (fragCoord - iResolution.xy / 2.0) / min(iResolution.x, iResolution.y);
    vec3 lens = normalize(vec3(ndc, 0.05));
	vec3 location = lens * 15.0 + vec3(0.0, 0.0, iTime);
	vec3 cellId = floor(location);
	vec3 relativeToCell = fract(location);
    vec3 locationOfStarInCell = fract(cross(cellId, vec3(2.154, -6.21, 0.42))) * 0.5 + 0.25;
	float star = max(0.0, 10.0 * (0.1 - distance(relativeToCell, locationOfStarInCell)));
	vec4 starsColor2 = vec4(star, star, star, 1.0);


    vec4 front  = texture(texture0, frontUV);
    vec4 back = col2 + bliksemColor + expColor + starsColor + starsColor2;
    float mask = step(0.1, max(max(front.r, front.g), front.b));  

    vec4 tmpColor = mix(back, front, mask);
    fragColor = tmpColor;
}
`;


/*   Init   */
ScrollCharacter* sc;
ScrollCharacter* sc2;
for (i in 0 ..< NR_LETTERS) {
    sc = &scrollChars[i];
    sc.Init();
}


// Loading sounds...
ptr soloudObject = soloud.Soloud_create();
int soloudResult = soloud.Soloud_init(soloudObject);
if (soloudResult != 0) return;
ptr explosionSfxr = soloud.Sfxr_create();
int sfxrLoaded = soloud.Sfxr_loadParams(explosionSfxr, "sound/sfxr/explosion.sfs");
if (sfxrLoaded != 0) return;
soloud.Sfxr_setVolume(explosionSfxr, 0.5f);

function playExplosion() { soloud.Soloud_play(soloudObject, explosionSfxr); }

function deleteSoundObjects() {
	soloud.Sfxr_destroy(explosionSfxr);
	soloud.Soloud_deinit(soloudObject);
	soloud.Soloud_destroy(soloudObject);
}



ptr processHandle = kernel32.GetCurrentProcess();
int oldPriorityClass = kernel32.GetPriorityClass(processHandle);
kernel32.SetPriorityClass(processHandle, KERNEL32_HIGH_PRIORITY_CLASS);
ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

raylib.SetConfigFlags(CONFIG_FLAG_VSYNC_HINT);
//raylib.ClearWindowState(CONFIG_FLAG_VSYNC_HINT); 
raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Tempo Typen");      //raylib.SetConfigFlags(CONFIG_FLAG_WINDOW_UNDECORATED or CONFIG_FLAG_WINDOW_MAXIMIZED);    //raylib.InitWindow(0, 0, "-");
f32 screenWidth = raylib.GetScreenWidth();
f32 screenHeight = raylib.GetScreenHeight();

raylib_Texture2D fontTexture = raylib.LoadTexture(GC_CurrentExeDir + "image/thefont_rgba_outline.png");
f32[2] screenTextureResolution = [ screenWidth, screenHeight ];

f32[16] iPoints = [ 
700.0f, 300.0f,
0.3f, 0.4f,
0.5f, 0.6f,
0.7f, 0.8f ];

ptr shader = raylib.LoadShaderFromMemory(vertexShader, fragmentShader);
int resolutionLocation = raylib.GetShaderLocation(shader, "iResolution");
int timeLocation = raylib.GetShaderLocation(shader, "iTime");
int iPointsLocation = raylib.GetShaderLocation(shader, "iPoints");
int explosionLocation = raylib.GetShaderLocation(shader, "explosion");
int explosionTimeLocation = raylib.GetShaderLocation(shader, "explosionTime");

raylib.SetShaderValue(shader, resolutionLocation, screenTextureResolution, SHADER_UNIFORM_VEC2);
raylib.SetShaderValueV(shader, iPointsLocation, iPoints, SHADER_UNIFORM_VEC2, 4);
raylib.HideCursor();

raylib_RenderTexture rt = raylib.LoadRenderTexture(screenWidth, screenHeight);
raylib_Texture2D rtTexture = &rt.texture_id;
raylib.SetTargetFPS(60);

raylib_Rectangle letterRect;
letterRect.x = 0.0f;
letterRect.y = 0.0f;
letterRect.width = 40.0f;
letterRect.height = 41.0f;

f32 mostRightX;
int mostRightIndex;
f32[2] explosionArray = [ 0.0f, 0.0f ];
f32 explosionTime = 0.0f;

#include soundtracker.g
SoundtrackerInit("sound/mod/back on earth.mod", 50);
//mikmod.Player_SetPosition(1);

while (!raylib.WindowShouldClose()) {
	SoundtrackerUpdate();

    f32 t = raylib.GetTime();
    raylib.SetShaderValue(shader, timeLocation, &t, SHADER_UNIFORM_FLOAT);
    raylib.SetShaderValueV(shader, iPointsLocation, iPoints, SHADER_UNIFORM_VEC2, 4);
    raylib.SetShaderValue(shader, explosionTimeLocation, &explosionTime, SHADER_UNIFORM_FLOAT);
    raylib.SetShaderValue(shader, explosionLocation, explosionArray, SHADER_UNIFORM_VEC2);

    raylib.BeginDrawing();

    raylib.BeginTextureMode(rt);
    raylib.ClearBackground(COLOR_BLACK);

    mostRightX = 0.0f;
    mostRightIndex = 0;
    for (i in 0 ..< NR_LETTERS) {
        sc = &scrollChars[i];
        if (sc.visible) {
            sc.MoveLeft();
            sc.CheckBounds();
            if (sc.visible == false) {
                explosionArray[0] = sc.position.x+40.0f;
                explosionArray[1] = sc.position.y+40.0f;
                explosionTime = t;
                //playExplosion();
            }
        }
        if (sc.visible) {
            letterRect.x = fontXOffsets[sc[0].theChar];
            letterRect.y = fontYOffsets[sc[0].theChar];
            if (sc.position.x > mostRightX) {
                mostRightX = sc.position.x;
                mostRightIndex = i;
            }
            raylib.DrawTextureRec(fontTexture,  &letterRect, sc[0].position, COLOR_WHITE);
        }
    }

    // rage quit if the NR_LETTERS is exceeded.
    if (mostRightIndex >= (NR_LETTERS-1))
        raylib.CloseWindow();


    // insert new character
    if (mostRightX < 1280.0f) {
        sc = &scrollChars[NR_LETTERS-1];
        sc.visible = true;
        sc.theChar = GetNewScrollLetter();
        sc.position.x = 1320.0f;
        for (i in 0 .. NR_LETTERS-2) {
            sc = &scrollChars[i];
            if (sc.theChar == ' ')
                sc.visible = false;
        }
    }

    // cleanup the array
    int needle = 0;
    for (i in 0 ..< NR_LETTERS) {
        sc = &scrollChars[i];
        sc2 = &scrollChars[needle];

        if (sc.visible and needle == 0 and (sc.theChar == '.' or sc.theChar == '?' or sc.theChar == '!' or sc.theChar == ','))
            continue;

        if (sc.visible) {
            if (needle != i) {
                sc2.theChar = sc.theChar;
                sc2.position.x = sc.position.x;
                sc2.position.y = sc.position.y;
                sc2.visible = sc.visible;
            }
            needle = needle + 1;
        }
    }
    for (i in needle ..< NR_LETTERS) {
        sc = &scrollChars[i];
        sc.visible = false;
    }

    sc = &scrollChars[0];
    if (sc.theChar == ' ') {
       iPoints[0] = 0.0f;
       iPoints[1] = 0.0f;
    } else if (sc.visible and sc.theChar != ' ') {
       iPoints[0] = sc.position.x+18.0f;
       iPoints[1] = sc.position.y+20.0f;
    }
    raylib.EndTextureMode();


    raylib.BeginShaderMode(shader);
    raylib.DrawTexture(rtTexture, 0, 0, COLOR_WHITE);
    raylib.EndShaderMode();


    //raylib.DrawFPS(SCREEN_WIDTH-100, 20);

    raylib.EndDrawing();

    int theKey = raylib.GetCharPressed();
    theKey = msvcrt.tolower(theKey);
    sc = &scrollChars[0];
    if (theKey == sc.theChar) {
        sc.visible = false;
        explosionArray[0] = sc.position.x+40.0f;
        explosionArray[1] = sc.position.y+40.0f;
        explosionTime = t;
        playExplosion();
    }
}
raylib.UnloadShader(shader);
raylib.CloseWindow();
SoundtrackerFree();
deleteSoundObjects();

function FreeMemory() {
	msvcrt.free(fontXOffsets);
	msvcrt.free(fontYOffsets);
}
FreeMemory();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
kernel32.SetPriorityClass(processHandle, oldPriorityClass);
