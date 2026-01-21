extends Node2D

@onready var inp_p = $InputPanel
@onready var banw = $InputPanel/ban_words
@onready var msin = $InputPanel/input
@onready var rawm = $InputPanel/rawmsg
@onready var sndb = $InputPanel/send
@onready var wtab = $InputPanel/writing_tab
@onready var npcint = $InputPanel/NPCINT
@onready var pnpc = $InputPanel/prevNPC
@onready var pico = $InputPanel/prevNPC/previcon
@onready var pmsg = $InputPanel/prevNPC/prevmsg
@onready var pbub = $InputPanel/prevNPC/prev_bubble

@onready var crd = $Card
@onready var cbg = $Card/CardBG
@onready var plbl = $Card/personality

@onready var rp = $result
@onready var finlbl = $result/finale
@onready var declbl = $result/declare

@onready var instp = $instruction
@onready var ilbl = $instruction/instruction
@onready var itab = $instruction/tab

@onready var cn = $coin
@onready var cq = $coin/quant
@onready var bkb = $back

var setinst = null

const msgs = [
	{
		"text": "Her Majesty's evening chalice has been laced with belladonna extract by the visiting diplomat. She must not drink during tonight's ceremonial toast.",
		"banned":  ["poison", "toxic", "drink", "cup", "chalice", "wine", "kill", "death", "diplomat", "queen", "majesty", "toast", "evening"]
	},
	{
		"text": "A cloaked figure with a concealed blade was spotted entering through the servant quarters. The Queen must relocate to the eastern tower immediately.",
		"banned": ["assassin", "killer", "blade", "knife", "weapon", "hide", "servant", "queen", "escape", "run", "tower", "danger", "attack"]
	},
	{
		"text": "The ruby pendant gifted by the northern ambassador contains a spring-loaded needle with venom. It must be removed before the Queen wears it to court.",
		"banned": ["trap", "poison", "needle", "venom", "pendant", "jewel", "gift", "ambassador", "queen", "remove", "danger", "deadly", "court"]
	},
	{
		"text": "Infiltrators have introduced arsenic into the flour stores. All pastries prepared for the royal banquet must be destroyed before serving.",
		"banned": ["spy", "poison", "arsenic", "flour", "food", "pastry", "cake", "banquet", "destroy", "throw", "royal", "infiltrate", "contaminate"]
	},
	{
		"text": "The marble pillars supporting the throne room balcony have been weakened with acid. The Queen must not stand beneath during tomorrow's address.",
		"banned": ["collapse", "fall", "destroy", "break", "pillar", "balcony", "throne", "queen", "stand", "danger", "weak", "acid", "address"]
	},
]

const folks = [
	{
		"name": "The Merchant",
		"personality": "A coin-obsessed traveling trader.\n\nConverts EVERYTHING to gold value.  Sees bribes and deals everywhere.  Adds fictional prices.  Thinks warnings are negotiation tactics.  Exaggerates worth tenfold.",
		"frame": "res://image/merchant_frame.png",
		"icon":  "res://image/merchant.png"
	},
	{
		"name": "The Boy",
		"personality":  "A daydreaming 6-year-old stable boy.\n\nTurns adults words into fairy tales. Replaces danger with dragons and monsters. Uses made-up words.  Gets distracted mid-message.  Everything becomes a game or adventure.",
		"frame": "res://image/boy_frame.png",
		"icon": "res://image/boy.png"
	},
	{
		"name": "The Guard",
		"personality": "A paranoid, conspiracy-obsessed guard.\n\nSees treason in every shadow. Uses excessive military codes. Suspects EVERYONE including the messenger. Adds unnecessary tactical formations.  Whispers dramatically.",
		"frame": "res://image/guard_frame.png",
		"icon": "res://image/guard.png"
	},
	{
		"name": "The Drunk",
		"personality": "The castle's legendary wine taster.\n\nSlurs consonants terribly. Forgets beginning by middle.  Hiccups interrupt words. Confuses rhyming words. Randomly toasts to things.  Emotional mood swings.",
		"frame": "res://image/drunk_frame.png",
		"icon": "res://image/drunk.png"
	},
	{
		"name": "The Scholar",
		"personality": "An insufferably pompous academic.\n\nUses 5 complex words when 1 works. Adds irrelevant historical references. Quotes philosophers nobody knows. Corrects grammar mid-crisis. Makes simple things incomprehensible.",
		"frame": "res://image/scholar_frame.png",
		"icon":  "res://image/scholar.png"
	},
]

const qframe = "res://image/queen_frame.png"

const instxt = """< ROYAL MESSENGER PROTOCOL >

You are the Queen's secret informant!  

 YOUR MISSION: 
Deliver an URGENT warning through a chain of 5 unreliable NPCs.  Rewrite the message WITHOUT using banned words!  
 THE CHAIN:  
Merchant → Boy → Guard → Drunk → Scholar → QUEEN
Each NPC will hilariously misinterpret what they hear.  Your goal:  make sure the Queen understands at least 50% of your warning!  

 WINNING CONDITIONS:
- Queen understands 50%+ of warning = SUCCESS
- Queen takes protective action = YOU GET PAID
- BOTH conditions = MAXIMUM COINS!  
- Good effort but Queen fails = Partial payment
  (Staff failure, not yours!)

 BANNED WORDS = INSTANT CAUGHT!
Use synonyms, metaphors, creative language! 
Press SEND when ready to begin!"""

const apiurl = "https://ai.hackclub.com/proxy/v1/chat/completions"
const apikey = ""

var http: HTTPRequest
var curstate = 0
var msgdat = {}
var rawmsg = ""
var curbanned = []
var plrmsg = ""
var npcidx = 0
var interps = []
var qres = {}
var totcoins = 0
var tylbl = null
var tytxt = ""
var tyidx = 0
var tyspd = 0.025
var tytim = 0.0
var typing = false
signal typdone
var curvis = true
var curtim = 0.0
var curspd = 0.4
var waitcur = false
var ctween = null
var warntim = null
const warntime = 3.0

func parsej(cnt):
	var p = JSON.parse_string(cnt)
	if p != null: return p
	var st = cnt.find("{")
	var en = cnt.rfind("}") + 1
	if st>=0 and en>st:
		return JSON.parse_string(cnt.substr(st,en-st))
	return null

func aierr():
	stopcur()
	npcint.text = "Connection error! Try again."
	sndb.disabled=false
	curstate=1
	msin.visible=true
	banw.visible=true
	wtab.visible=true
	crd.visible=false
	pnpc.visible=false

func airesponse(res,_rc,_h,bod):
	stopcur()
	if res!=HTTPRequest.RESULT_SUCCESS:
		aierr()
		return
	var jstr=bod.get_string_from_utf8()
	var j=JSON.parse_string(jstr)
	if j==null or not j.has("choices"):
		aierr()
		return
	var c=j["choices"][0]["message"]["content"]
	var prs=parsej(c)
	if prs!=null and prs.has("chain"):
		interps=prs["chain"]
		qres=prs.get("queen",{"understanding":"I don't understand...","action":"Nothing","survival_score":0,"action_taken":false})
		shownpc()
	else:
		aierr()

func aireq():
	var tls=TLSOptions.client()
	http.set_tls_options(tls)
	
	var npclist=""
	for i in range(folks.size()):
		npclist+=str(i+1)+". "+folks[i]["name"]+": "+folks[i]["personality"].split("\n")[0]+"\n"
	
	var sysp="""You are simulating a medieval telephone game where a message passes through 5 NPCs with distinct personalities.

 CRITICAL: NPCs ARE REAL PEOPLE WITH COMMON SENSE 
- NPCs can ONLY work with UNDERSTANDABLE language
- If a message is gibberish (random letters like "khjkfdghkdfg"), NPCs will say "I don't understand what you're saying" or similar
- If a message is completely unrelated to any warning or danger, NPCs will be confused: "What does this mean?"
- NPCs need AT LEAST recognizable words to misinterpret - they cannot magically decode nonsense
- Only proceed with personality-based misinterpretations if the message contains actual WORDS and MEANING

VALIDATION FIRST (MOST IMPORTANT):
1. Is the player's message actual language? (Not random characters)
2. Does it contain real words that relate to danger, warning, or the castle?
3. Can a human reasonably extract ANY meaning from it?
4. If NO to any above → ALL NPCs respond with confusion/inability to understand

NPC BEHAVIOR RULES:
1. Each NPC ONLY hears what the PREVIOUS NPC said (NOT the original message)
2. NPCs apply personality quirks ONLY to understandable messages
3. Keep each NPC message 1-2 sentences, in-character
4. NPCs use common sense and synonyms (e.g., "column" for pillar, "goblet" for chalice)
5. If they receive gibberish from previous NPC, they say "I cannot make sense of this" in their personality style

NPCs IN ORDER:
"""+npclist+"""

THE QUEEN (Final Recipient):
- The Queen receives a scroll showing ALL 5 NPC interpretations in order
- She reads the ENTIRE chain: Merchant > Boy > Guard > Drunk > Scholar
- She tries to piece together the real warning by analyzing the whole garbled message chain
- She's wise and looks for patterns across all messages to understand the true danger
- She decides what action to take based on her analysis of the complete chain

QUEEN'S ANALYSIS:
- understanding: What she thinks the REAL warning is after reading all NPC messages
- action: What specific protective action she decides to take
- survival_score (0-100): How much of the ORIGINAL warning's meaning she successfully extracted
  * 0 = Complete gibberish, no meaning extractable
  * 1-20 = Mostly gibberish or completely wrong understanding
  * 21-49 = Partial understanding but won't act
  * 50-79 = Good understanding, will likely act
  * 80-100 = Excellent understanding and clear action
- action_taken (true/false): Did she take ANY protective action?
  * false if message was gibberish or incomprehensible
  * false if she's too confused to act
  * true only if she understood enough to take precaution

EXAMPLES:
 >BAD INPUT: "khjkfdghkdfg" or "asdfghjkl" or "blah blah blah"
> Merchant: "I don't understand these strange sounds..."
 >Boy: "The man said weird noises!"
 >Guard: "Report unclear, suspected nonsense!"
 >Drunk: "*hic* What? Can't... understand..."
 >Scholar: "Incomprehensible utterings, devoid of semantic content."
 >Queen: understanding="I have no idea what this message means", survival_score=0, action_taken=false

✅ GOOD INPUT: "The evening beverage container has bad plant juice from the foreign visitor"
→ NPCs misinterpret with their personalities BUT they understand it's about danger
→ Queen can piece together it's about poison and a diplomat
→ survival_score = 60-80, action_taken = true

RESPOND ONLY IN VALID JSON (no markdown, no extra text):
{
  "chain": [
    {"npc": "The Merchant", "message": "..."},
    {"npc": "The Boy", "message": "..."},
    {"npc": "The Guard", "message": "..."},
    {"npc": "The Drunk", "message": "..."},
    {"npc": "The Scholar", "message": "..."}
  ],
  "queen": {
    "understanding": "What the Queen deduces after reading all 5 NPC messages",
    "action": "What specific action the Queen decides to take",
    "survival_score": 0-100,
    "action_taken": true or false
  }
}"""

	var usrm="""ORIGINAL SECRET WARNING (for your reference only):
"%s"

PLAYER'S ENCODED MESSAGE (what the Merchant hears):
"%s"

Simulate the chain! Remember: each NPC only hears the previous one, but the Queen reads ALL 5 interpretations on a scroll."""%[rawmsg,plrmsg]

	var hdr=["Content-Type: application/json","Authorization: Bearer "+apikey]
	var bod={"model":"gpt-4o-mini","messages":[{"role":"system","content":sysp},{"role":"user","content":usrm}],"temperature":0.85,"max_tokens":1500}
	var e=http.request(apiurl,hdr,HTTPClient.METHOD_POST,JSON.stringify(bod))
	if e!=OK:
		stopcur()
		aierr()

func _ready():
	http=HTTPRequest.new()
	http.use_threads=true
	add_child(http)
	http.request_completed.connect(airesponse)
	
	warntim=Timer.new()
	warntim.one_shot=true
	warntim.timeout.connect(resetwarn)
	add_child(warntim)
	
	sndb.pressed.connect(btnpress)
	bkb.pressed.connect(goback)
	
	setupwrap()
	loadcoins()
	startinst()

func setupwrap():
	rawm.autowrap_mode=TextServer.AUTOWRAP_WORD
	banw.autowrap_mode=TextServer.AUTOWRAP_WORD
	plbl.autowrap_mode=TextServer.AUTOWRAP_WORD
	pmsg.autowrap_mode=TextServer.AUTOWRAP_WORD
	npcint.autowrap_mode=TextServer.AUTOWRAP_WORD
	ilbl.autowrap_mode=TextServer.AUTOWRAP_WORD
	finlbl.autowrap_mode=TextServer.AUTOWRAP_WORD
	declbl.autowrap_mode=TextServer.AUTOWRAP_WORD

func loadcoins():
	cq.text=str(totcoins)

func updcoins(amt):
	totcoins+=amt
	cq.text=str(totcoins)

func goback():
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://main.tscn")

func loadnpcf(idx):
	var f=folks[idx]
	if ResourceLoader.exists(f["frame"]):
		cbg.texture=load(f["frame"])

func loadqf():
	if ResourceLoader.exists(qframe):
		cbg.texture=load(qframe)

func loadpico(idx):
	var f=folks[idx]
	if ResourceLoader.exists(f["icon"]):
		pico.texture=load(f["icon"])

func animswap(cb):
	if ctween: ctween.kill()
	ctween=create_tween()
	var oscl=crd.scale
	ctween.tween_property(crd,"scale",Vector2(0.8,0.8),0.15).set_ease(Tween.EASE_IN)
	ctween.parallel().tween_property(crd,"modulate:a",0.0,0.15)
	ctween.tween_callback(cb)
	ctween.tween_property(crd,"scale",oscl,0.15).set_ease(Tween.EASE_OUT)
	ctween.parallel().tween_property(crd,"modulate:a",1.0,0.15)
	await ctween.finished

func animenter():
	if ctween: ctween.kill()
	ctween=create_tween()
	var tpos=crd.position
	crd.position.x+=200
	crd.scale=Vector2(0.5,0.5)
	crd.modulate.a=0.0
	ctween.tween_property(crd,"position",tpos,0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	ctween.parallel().tween_property(crd,"scale",Vector2(1,1),0.3).set_ease(Tween.EASE_OUT)
	ctween.parallel().tween_property(crd,"modulate:a",1.0,0.2)
	await ctween.finished

func _process(dlt):
	if typing:
		tytim+=dlt
		while tytim>=tyspd and tyidx<tytxt.length():
			tytim-=tyspd
			tyidx+=1
			tylbl.text=tytxt.substr(0,tyidx)+"|"
			AudioManager.play_typing()
		if tyidx>=tytxt.length():
			typing=false
			tylbl.text=tytxt
			AudioManager.stop_typing()
			typdone.emit()
	
	if waitcur:
		curtim+=dlt
		if curtim>=curspd:
			curtim=0.0
			curvis=!curvis
			if curvis: npcint.text="|"
			else: npcint.text=""

func typ(lbl,tx):
	tylbl=lbl
	tytxt=tx
	tyidx=0
	tytim=0.0
	typing=true
	lbl.text="|"

func startcur():
	waitcur=true
	curtim=0.0
	curvis=true
	npcint.text="|"

func stopcur():
	waitcur=false
	npcint.text=""

func resetwarn():
	if curstate==1:
		typ(banw," BANNED:  "+", ".join(curbanned))

func btnpress():
	AudioManager.play_click()
	match curstate:
		0: startinp()
		1: sendit()
		3: gonext()
		4: restartit()

func startinst():
	curstate=0
	inp_p.visible=true
	msin.visible=false
	banw.visible=false
	wtab.visible=false
	pnpc.visible=false
	pbub.visible=false
	crd.visible=false
	rp.visible=false
	npcint.visible=false
	npcint.text=""
	rawm.visible=false
	rawm.text=""
	instp.visible=true
	sndb.disabled=false
	sndb.visible=true
	typ(ilbl,instxt)
	await typdone

func startinp():
	curstate=1
	instp.visible=false
	inp_p.visible=true
	msin.visible=true
	banw.visible=true
	wtab.visible=true
	rawm.visible=true
	pnpc.visible=false
	pbub.visible=false
	crd.visible=false
	rp.visible=false
	npcint.visible=false
	npcint.text=""
	sndb.disabled=false
	sndb.visible=true
	npcidx=0
	interps.clear()
	qres.clear()
	msgdat=msgs[randi()%msgs.size()]
	rawmsg=msgdat["text"]
	curbanned=msgdat["banned"]
	msin.text=""
	typ(rawm,rawmsg)
	await typdone
	typ(banw," BANNED:  "+", ".join(curbanned))
	await typdone

func sendit():
	var t=msin.text.strip_edges()
	if t.is_empty():
		typ(banw," Write something first!")
		warntim.start(warntime)
		return
	if t.length()<10:
		typ(banw," Message too short! Be more creative!")
		warntim.start(warntime)
		return
	var fnd=[]
	for w in curbanned:
		if t.to_lower().contains(w.to_lower()):
			fnd.append(w)
	if fnd.size()>0:
		typ(banw," CAUGHT!  "+", ".join(fnd))
		warntim.start(warntime)
		return
	plrmsg=t
	curstate=2
	sndb.disabled=true
	msin.visible=false
	banw.visible=false
	wtab.visible=false
	instp.visible=false
	pnpc.visible=true
	pbub.visible=true
	pico.visible=false
	pmsg.text="Your message:\n\""+plrmsg+"\""
	npcint.visible=true
	rawm.visible=true
	crd.visible=true
	loadnpcf(0)
	plbl.text=folks[0]["name"]+"\n\n"+folks[0]["personality"]
	await animenter()
	startcur()
	aireq()

func shownpc():
	curstate=3
	inp_p.visible=true
	msin.visible=false
	banw.visible=false
	wtab.visible=false
	instp.visible=false
	pnpc.visible=true
	pbub.visible=true
	npcint.visible=true
	rawm.visible=true
	crd.visible=true
	rp.visible=false
	sndb.disabled=false
	npcidx=0
	shwcur()

func shwcur():
	if npcidx>=interps.size():
		showq()
		return
	var npc=folks[npcidx]
	var itp=interps[npcidx]
	sndb.disabled=true
	loadnpcf(npcidx)
	plbl.text=npc["name"]+"\n\n"+npc["personality"]
	if npcidx>0:
		pico.visible=true
		loadpico(npcidx-1)
		var pitp=interps[npcidx-1]
		var ptx=pitp.get("message","...")
		if ptx.length()>80: ptx=ptx.substr(0,77)+"..."
		pmsg.text=folks[npcidx-1]["name"]+" said:\n\""+ptx+"\""
	else:
		pico.visible=false
		pmsg.text="Your message:\n\""+plrmsg+"\""
	var m=itp.get("message","...")
	typ(npcint,"\""+m+"\"")
	await typdone
	sndb.disabled=false

func gonext():
	npcidx+=1
	if npcidx>=interps.size():
		showq()
	else:
		await animswap(shwcur)

func showq():
	curstate=4
	npcint.visible=false
	npcint.text=""
	rawm.visible=false
	rawm.text=""
	pnpc.visible=false
	pbub.visible=false
	crd.visible=false
	rp.visible=true
	finlbl.text=""
	declbl.text=""
	loadqf()
	crd.visible=true
	plbl.text=" THE QUEEN\n\nThe wise and powerful ruler.\nShe will judge your message."
	await animenter()
	var surv=qres.get("survival_score",0)
	var actd=qres.get("action_taken",false)
	var undr=qres.get("understanding","...")
	var act=qres.get("action","Nothing")
	var msuccess=surv>=50
	var asuccess=actd
	var fullsuc=msuccess and asuccess
	var cerns=0
	if fullsuc:
		if surv>=80: cerns=100
		else: cerns=50
	elif msuccess or asuccess: cerns=25
	else: cerns=0
	var fintx=" QUEEN'S INTERPRETATION:\n\n\""+undr+"\"\n\n⚔ ACTION: "+act
	typ(finlbl,fintx)
	await typdone
	await get_tree().create_timer(0.5).timeout
	var dectx=makedecl(surv,actd,msuccess,asuccess,cerns)
	typ(declbl,dectx)
	await typdone
	if cerns>0: updcoins(cerns)
	sndb.visible=true
	sndb.disabled=false

func makedecl(surv,actd,msuc,asuc,coins)->String:
	var tx=" SURVIVAL SCORE: "+str(surv)+"%\n\n"
	if msuc and asuc:
		tx+=" PERFECT SUCCESS!\n\n"
		tx+="The Queen understood your warning AND took protective action!  "
		tx+="The kingdom is safe thanks to your clever wordplay!\n\n"
		tx+=" REWARD: "+str(coins)+" COINS!"
	elif msuc:
		tx+=" MESSAGE DELIVERED!\n\n"
		tx+="The Queen understood most of your warning, but didn't act on it. "
		tx+="Still, you did well!\n\n"
		tx+=" REWARD:  "+str(coins)+" COINS!"
	elif asuc:
		tx+=" ACTION TAKEN!\n\n"
		tx+="The Queen didn't fully understand, but something felt wrong...  "
		tx+="She took precautions anyway!  Sometimes instinct saves the day.\n\n"
		tx+="You did your job - the staff garbled it.  Here's your pay!\n\n"
		tx+=" REWARD:  "+str(coins)+" COINS!"
	else:
		tx+=" MISSION FAILED...\n\n"
		tx+="The Queen understood nothing and took no action. "
		tx+="The message was lost in the chain of fools.\n\n"
		tx+="No coins this time. Try again with better word choices!"
	return tx

func restartit():
	crd.visible=false
	rp.visible=false
	startinp()
