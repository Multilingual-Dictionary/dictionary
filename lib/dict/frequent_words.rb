class FrequentWords 
	def initialize()
		@words = Hash.new
	end
	def init_de()
		printf("Init DE\n")
       		["die","der","und","in","zu","den","das","nicht","von","sie",
		"ist","des","sich","mit","dem","dass","er","es","ein","ich",
	        "auf","so","eine","auch","als","an","nach","wie","im","für",
		"man","aber","aus","durch","wenn","nur","war","noch","werden",
		"bei","hat","wir","was","wird","sein","einen","welche","sind",
		"oder","zur","um","haben","einer","mir","über","ihm","diese",
		"einem","ihr","uns","da","zum","kann","doch","vor","dieser",
		"mich","ihn","du","hatte","seine","mehr","am","denn","nun",	
		"unter","sehr","selbst","schon","hier","bis","habe","ihre","dann",	
		"ihnen","seiner","alle","wieder","meine","gegen","vom","ganz",	
		"einzelnen","wo","muss","ohne","eines","können","sei","ja",
		"wurde","jetzt","immer","seinen","wohl","dieses","ihren","würde",
		"diesen","sondern","weil","welcher","nichts","diesem","alles",
		"waren","will","viel","mein","also","soll","worden","lassen",	
		"dies","machen","ihrer","weiter","Leben","recht","etwas","keine",	
		"seinem","ob","dir","allen","großen","Weise","müssen","welches",	
		"wäre","erst","einmal","Mann","hätte","zwei","dich","allein","während",	
		"anders","kein","damit","gar","euch","sollte","konnte","ersten",
		"deren","zwischen","wollen","denen","dessen","sagen","bin","gut",
		"darauf","wurden","weiß","gewesen",	"Seite","bald","weit","große",
		"solche","hatten","eben","andern",	"beiden","macht","sehen",
		"ganze","anderen","lange","wer","ihrem",
		"zwar","gemacht","dort","kommen","heute","werde","derselben",
		"ganzen","lässt","vielleicht","meiner"
		].each{|w|
			@words['DE'][w.downcase]=1
		}
	end
	def init_en()
		printf("Init EN\n")
		["the","and","of","a","in","to",
		"I","it","to","that","for","you","he",
		"with","on","this","they","we","his","but",
		"at","that","not","from","n't","by","she",
		"or","as","what","their","who","her","if",
		"my","all","about","as","up","there","one",
		"so","me","which","when","out","them","just",
		"him","some","into","your","now","than","like",
		"then","its","how","our","more","these","two",
		"also","first","because","more","here","well","no",
		"her","very","many","only","those","one","back",
		"even","us","any","through","there","down","after",
		"over","still","last","in","as","too","when",
		"three","between","really","never","something","most","much",
		"out","another","own","on","why","while","same",
		"where","every","about","over","such","again","right",
		"against","few","most","each","where","so","during",
		"off","today","always","all","million","next","before",
		"without","under","yes","though","four","far","both",
		"away","around","after","however","long","since","until",
		"often","among","ever","yet","almost","nothing","later",
		"once","much","five","ago","several","least","around",
		"whether","anything","together","such","already","within","himself",
		"maybe","although","before","both","toward","enough","across",
		"actually","off","including","second","oh","everything","yeah",
		"probably","home","course","someone","behind","six","former",
		"little","else","perhaps","up","themselves","along","sometimes",
		"according","less","finally","even","better","because","especially",
		"early","whose","everyone","itself","half"
		].each{|w|
			@words['EN'][w.downcase]=1
		}
	end
	def too_frequent(w,lang)
		lang = lang.upcase
		if @words[lang]==nil
			@words[lang]=Hash.new
			case lang
			when 'EN'
				init_en()
			when 'DE'
				init_de()
			else
			end
		end
		return true if @words[lang][w.downcase]!=nil
		return true if w.index(/[0-9]/) != nil
		return false
	end
end
