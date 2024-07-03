extends Node

var N = 4  +4 # data len
const V = 16 # 2^ encoder memory size

var empty := [] # 3D array od size 2xNxV
var error_arr := []

#data, endoded and result of decoding to be used betwen functions
var X := []
var Y := []
var D := []

var tests = 100
var iterations = 4
var errors = 0

func _ready():
	randomize()

var iters = 0
var fail = 0
var BER = 0

var RUNNING = false

#begin set of tests, called by ui
func start_test():
	iters = 0
	fail = 0
	BER = 0
	
	get_node("../ui/Panel4/BER").text = "BER: ?"
	get_node("../ui/Panel4/PER").text = "PER: ?"
	
	make_empty()
	make_errs(errors)
	RUNNING = true

#run singnle test, called by ui
func run_one_test():
	
	iters = 0
	fail = 0
	BER = 0
	make_errs(errors)
	make_empty()
	
	var plaintext = get_node("../ui/Panel3/LineEdit").text
	
	if plaintext.is_empty() or not plaintext.is_valid_int():
		get_node("../ui/Panel3/is_ok").text = "Invalid input"
		return
	
	for i in plaintext:
		if not(i=="0" or i=="1"):
			get_node("../ui/Panel3/is_ok").text = "Invalid input"
			return
	
	if plaintext.length() > N-4:
		plaintext = plaintext.substr(0,N-4)
		
	elif plaintext.length() < N-4:
		
		while plaintext.length() < N-4:
			plaintext+=LSFR()
	
	
	var msg = encode_massage(plaintext)
	
	plaintext = msg.substr(0,N-4)
	
	var sent = make_err(msg)
	
	var decoded = decode_message(sent,iterations)
	
	decoded = decoded.substr(0,N-4)
	
	get_node("../ui/Panel3/LineEdit").text = plaintext
	get_node("../ui/Panel3/wyslane").text = msg
	get_node("../ui/Panel3/odebrane").text = sent
	get_node("../ui/Panel3/zdekodowane").text = decoded
	
	if plaintext == decoded:
		get_node("../ui/Panel3/is_ok").text = "OK"
		get_node("../ui/Panel2/RichTextLabel").add_text("\nOK "+msg+" "+sent+" "+decoded)
		#print("OK "+msg+" "+sent+" "+decoded)
		
	else:
		get_node("../ui/Panel3/is_ok").text = "FAIL"
		get_node("../ui/Panel2/RichTextLabel").add_text("\nFAIL "+msg+" "+sent+" "+decoded+" "+plaintext)
		#print("FAIL "+msg+" "+sent+" "+decoded+" "+plaintext)
		
		fail += 1
		for i in plaintext.length():
			if decoded[i] != plaintext[i]:
				BER+=1
	
	
	pass


# run one test per frame to not cause a crash
func _process(delta):
	if RUNNING == false:
		return
	iters+=1
	
	if iters > tests:
		
		get_node("../ui/Panel4/BER").text = "BER: "+str( float(BER)/float(tests*(N-4)) )
		get_node("../ui/Panel4/PER").text = "PER: "+str( float(fail)/float(tests) )
		
		RUNNING = false
		get_parent().stop_test()
#		print("channel error rate: "+str(float(errors)/float(N*3)))
#		print("wrong packets: "+str(fail))
#		print("PER: "+str( float(fail)/float(tests) ))
#		print("wrong bits: "+str(BER))
#		print("BER: "+str( float(BER)/float(tests*(N-4)) ))
		
		return
	
	
	var plaintext = ""
	for i in N-4:
		plaintext+=LSFR()
	
	var msg = encode_massage(plaintext)
	
	plaintext = msg.substr(0,N-4)
	
	var sent = make_err(msg)
	
	var decoded = decode_message(sent,iterations)
	
	decoded = decoded.substr(0,N-4)
	
	
	get_node("../ui/Panel3/LineEdit").text = plaintext
	get_node("../ui/Panel3/wyslane").text = msg
	get_node("../ui/Panel3/odebrane").text = sent
	get_node("../ui/Panel3/zdekodowane").text = decoded
	get_node("../ui/Panel3/iter").text = "Iteration: "+str(iters)
	
	if plaintext == decoded:
		get_node("../ui/Panel3/is_ok").text = "OK"
		get_node("../ui/Panel2/RichTextLabel").add_text("\nOK "+msg+" "+sent+" "+decoded)
		#print("OK "+msg+" "+sent+" "+decoded)
		
	else:
		get_node("../ui/Panel3/is_ok").text = "FAIL"
		get_node("../ui/Panel2/RichTextLabel").add_text("\nFAIL "+msg+" "+sent+" "+decoded+" "+plaintext)
		#print("FAIL "+msg+" "+sent+" "+decoded+" "+plaintext)
		
		fail += 1
		for i in plaintext.length():
			if decoded[i] != plaintext[i]:
				BER+=1
	

#inverts a number of bits given by non zero elements of error_arr
func make_err(msg:String)->String:
	
	error_arr.shuffle()
	
	for e in msg.length():
		if error_arr[e] != 0:
			if msg[e] == '1':
				msg[e] = '0'
			else:
				msg[e] = '1'
		
	return msg

#make packet by joining plaintext, result of coder and interlieved coder
func encode_massage(plaintext:String)->String:
	
	var c1 = encoder(plaintext)
	var encoded1 = c1[0]
	#add bits to plaintext, that will make the coder end in '0' state
	plaintext = plaintext + str(c1[1][3]) + str(c1[1][2]) + str(c1[1][1]) + str(c1[1][0])
	var c2 = encoder(interliver_str(plaintext))
	#remove the '0' bits from second coder
	var encoded2 = c2[0].substr(0,plaintext.length())
	
	return plaintext+encoded1+encoded2

#turbo code- run the result of decoding through decoder a number of times given by the iterations variable
func decode_message(msg:String,iterations1:int)->String:
	
	var plaintext = msg.substr(0,N)
	var encoded1= msg.substr(N,N)
	var encoded2= msg.substr(2*N,N)
	var x0 = []
	
	#make plaintext ba a float
	for i in plaintext:
		if i == '1':
			x0.push_back(1.0)
		else:
			x0.push_back(-1.0)
	
	#first iteration of both decoders
	var L1 = decoder(x0,encoded1,true)
	var L2  = decoder(interliver_arr(L1),encoded2,false)
	L2 = deinterliver_arr(L2)
	for i in L1.size():
		L2[i] = L2[i]-L1[i]
	var L3 = L2.duplicate()
	for i in L1.size():
		L3[i] = x0[i]+L1[i]
	
	iterations1 -= 1
	
	while iterations1 > 1:
		
		L1 = decoder(L3,encoded1,true)
		
		for i in L1.size():
			L1[i] = L1[i]-L2[i]
		
		L2  = decoder(interliver_arr(L1),encoded2,false)
		L2 = deinterliver_arr(L2)
		
		for i in L1.size():
			L2[i] = L2[i]-L1[i]
		for i in L1.size():
			L3[i] = x0[i]+L2[i]
		
		iterations1 -= 1
	
	#last iteration
	L1 = decoder(L3,encoded1,true)
	
	for i in L1.size():
		L1[i] = L1[i]-L2[i]
	
	L2  = decoder(interliver_arr(L1),encoded2,false)
	L2 = deinterliver_arr(L2)
	
	#hard decision
	var solution = ""
	for i in L2:
		if i >= 0:
			solution+= "1"
		else:
			solution+="0"
	
	return solution

#single decoder. takes in data and encoded data, also if first the coder enden in '0' state. if not it only started in it.
func decoder(data:Array,enc:String,first:bool) -> Array:
	
	
	X.clear()
	Y.clear()
	for a in enc:
		Y.push_back(int(a))
	X = data.duplicate(true)
	
	D = empty.duplicate(true)
	
	#compute the delta table
	for i in 2:
		for k in N:
			for m in V:
				D[i][k][m] = delta(i,m,X[k],Y[k])
	
	#compute the alpha and beta trellis tables
	var A = alpha()
	var B = beta(first)
	#compute the probability (L)
	var L = Probb_L(A,B)
	
	return L




func delta(i:int,m:int,x:float,y:int)->float:
	
	var yc = 2*encode_for(i,m)-1
	i = 2*i -1
	y = (2*y -1)
	return exp(0.5*( x*i + y*yc )) 
	

func beta(sure:bool) -> Array:
	
	var B = empty.duplicate(true)
	
	if sure:
		B[0][N-1][S_back(0,0)] = 1.0
		B[1][N-1][S_back(1,0)] = 1.0
	else:
		for m in V:
			B[0][N-1][m] = 1.0/V
			B[1][N-1][m] = 1.0/V
	
	for k in range(N-2,-1,-1):
		for m in V:
			for i in 2:
				B[i][k][m] = B[0][k+1][S_forw(i,m)]*D[0][k+1][S_forw(i,m)] + B[1][k+1][S_forw(i,m)]*D[1][k+1][S_forw(i,m)]
	
	return B

func alpha() -> Array:
	
	var A = empty.duplicate(true)
	
	A[0][0][0] = delta(0,0,X[0],Y[0])
	A[1][0][0] = delta(1,0,X[0],Y[0])
	
	for k in range(1,N):
		for m in V:
			for i in 2:
				A[i][k][m] = D[i][k][m] * (A[0][k-1][S_back(0,m)] + A[1][k-1][S_back(1,m)])
	
	return A

func Probb_L(A:Array,B:Array) -> Array:
	
	var L = []
	
	var top := 0.0
	var bot := 0.0
	
	for k in N:
		top = 0.0
		bot = 0.0
		for m in V:
			top += A[1][k][m]*B[1][k][m]
			bot += A[0][k][m]*B[0][k][m]
		
		L.push_back( log( top/bot ) )
	
	return L
 

#find the previous coder state
func S_back(dk:int,state:int)->int:
	var s = []
	
	while (state > 0):
		s.push_front(state & 1)
		state = (state >> 1)
	
	while s.size() < 4:
		s.push_front(0)
	
	var z = (s[0]-dk+2)%2
	s.push_back(z)
	var sym = str(s[1])+str(s[2])+str(s[3])+str(s[4])
	
	var out = 0
	for c in sym:
		out = (out << 1) + int(c == "1")
	return out

#find the next coder state
func S_forw(dk:int,state:int)->int:
	var s = []
	
	while (state > 0):
		s.push_front(state & 1)
		state = (state >> 1)
	
	while s.size() < 4:
		s.push_front(0)
	
	var z = (dk+s[3])%2
	s.push_front(z)
	var sym = str(s[0])+str(s[1])+str(s[2])+str(s[3])
	
	var out = 0
	for c in sym:
		out = (out << 1) + int(c == "1")
	return out
	

#find the result of encoding given bit with given coder state
func encode_for(val:int,state:int)->int:
	var mem = []
	
	while (state > 0):
		mem.push_front(state & 1)
		state = (state >> 1)
	
	while mem.size() < 4:
		mem.push_front(0)
	
	var curr = (mem[3]+val)%2
	mem.push_front(curr)
	
	return (mem[0]+mem[1]+mem[2]+mem[3]+mem[4])%2

#convolution coder with returning to '0' state capability
func encoder(plain : String)-> Array:
	
	var encoded = ""
	var mem = [0,0,0,0]
	for i in plain:
		var curr = int(i)
		curr = (mem[3]+curr)%2
		mem.push_front(curr)
		encoded += str((mem[0]+mem[1]+mem[2]+mem[3]+mem[4])%2)
	
	var end_state = [mem[0],mem[1],mem[2],mem[3]]
	
	
	var t = end_state.duplicate()
	t.reverse()
	
	for i in t:
		mem.push_front((mem[3]+i)%2)
		encoded += str((mem[0]+mem[1]+mem[2]+mem[3]+mem[4])%2)
	
	#returns encoded plaintext longer by 4 bits and its state from 4 bits age - if reversed and added to plaintext will return coder to '0' state
	return [encoded, end_state]

#interliver for arrays
func interliver_arr(s:Array)->Array:
	var b = []
	var a = []
	
	var i = 0
	
	while i < s.size()+3:
		
		if i > s.size()-1:
			i = i - s.size() + 1
		
		a.push_back(s[i])
		i += 4
		
	
	for j in range((s.size()/2)-1,-1,-1):
		b.push_back(a[j])
	for j in range(s.size()-1,(s.size()/2)-1,-1):
		b.push_back(a[j])
	
	
	return b
#deinterliver for arrays
func deinterliver_arr(s:Array)->Array:
	var b = []
	var a = []
	
	for j in range((s.size()/2)-1,-1,-1):
		b.push_back(s[j])
	for j in range(s.size()-1,(s.size()/2)-1,-1):
		b.push_back(s[j])
	
	var i = 0
	var k = s.size()/4
	
	while i < s.size()+k-1:
		
		if i > s.size()-1:
			i = i - s.size() + 1
		
		a.push_back(b[i])
		i += k
	
	return a
#interliver for strings
func interliver_str(s:String)->String:
	var b = ""
	var a = ""
	
	var i = 0
	
	while i < s.length()+3:
		
		if i > s.length()-1:
			i = i - s.length() + 1
		
		a+=s[i]
		i += 4
		
	
	for j in range((s.length()/2)-1,-1,-1):
		b+= a[j]
	for j in range(s.length()-1,(s.length()/2)-1,-1):
		b+= a[j]
	
	return b
#makes empty arrays of correct sizes to be copied
func make_empty()->void:
	empty.clear()
	
	var half = []
	var quot = []
	for b in V:
		quot.push_back(0)
	for a in N:
		half.push_back(quot.duplicate(true))
	empty.push_back(half.duplicate(true))
	empty.push_back(half.duplicate(true))
#makes the error_arr
func make_errs(num)->void:
	error_arr.clear()
	
	if num > N*3: num = N*3
	
	for i in num:
		error_arr.push_back(1)
	while error_arr.size() < N*3:
		error_arr.push_back(0)

#lsfr for random number generation (not nesesary but required by the project)
var lsfr_state = randi_range(1,32766)
func LSFR()->String:
	
	var bit = (lsfr_state ^ (lsfr_state >> 1)) & 1
	lsfr_state = (lsfr_state >> 1) | (bit << 14)
	
	return str(bit)
