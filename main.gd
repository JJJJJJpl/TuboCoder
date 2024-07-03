extends Control

func _on_dl_wiad_value_changed(value):
	$ui/Panel/DL_pak.text =  str((value+4)*3)
	$ui/Panel/zle_bity.max_value = (value+4)*3
	$ui/Panel/BER2.text = str(float($ui/Panel/zle_bity.value)/float((value+4)*3))
	$code.N = value+4


func _on_zle_bity_value_changed(value):
	$ui/Panel/BER2.text = str(float(value)/float(int($ui/Panel/DL_pak.text)))
	$code.errors = value


func _on_ilosc_iteracji_value_changed(value):
	$code.iterations = value


func _on_ilosc_testow_value_changed(value):
	$code.tests = value


func _on_button_pressed():
	$ui/Panel/zle_bity.editable = false
	$ui/Panel/ilosc_iteracji.editable = false
	$ui/Panel/ilosc_testow.editable = false
	$ui/Panel/dl_wiad.editable = false
	$ui/Panel3/LineEdit.editable = false
	$ui/Button.disabled = true
	$ui/Button2.disabled = true
	$ui/Button3.disabled = false
	$code.start_test()


func stop_test():
	$ui/Panel/zle_bity.editable = true
	$ui/Panel/ilosc_iteracji.editable = true
	$ui/Panel/ilosc_testow.editable = true
	$ui/Panel/dl_wiad.editable = true
	$ui/Panel3/LineEdit.editable = true
	$ui/Button.disabled = false
	$ui/Button2.disabled = false
	$ui/Button3.disabled = true
	$code.RUNNING = false

func _on_button_2_pressed():
	$code.run_one_test()
