package dto

type TranslateLineReq struct {
	TargetLang        string `json:"target_lang"`
	PreviousSentences string `json:"previous_sentences"`
	TargetSentence    string `json:"target_sentence"`
	NextSentences     string `json:"next_sentences"`
}

type TranslateLineResData struct {
	Text  string `json:"text"`
	Model string `json:"model"`
}

