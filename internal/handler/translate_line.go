package handler

import (
	"krillin-ai/internal/dto"
	"krillin-ai/internal/response"
	"krillin-ai/internal/types"
	"krillin-ai/log"
	"strings"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func (h Handler) TranslateLine(c *gin.Context) {
	var req dto.TranslateLineReq
	if err := c.ShouldBindJSON(&req); err != nil {
		log.GetLogger().Error("TranslateLine ShouldBindJSON err", zap.Error(err))
		response.R(c, response.Response{Error: -1, Msg: "参数错误", Data: nil})
		return
	}

	targetLang := strings.TrimSpace(req.TargetLang)
	if targetLang == "" {
		targetLang = "vi"
	}
	targetSentence := strings.TrimSpace(req.TargetSentence)
	if targetSentence == "" {
		response.R(c, response.Response{Error: -1, Msg: "target_sentence 为空", Data: nil})
		return
	}

	text, model, err := h.Service.TranslateDialogueLine(
		c.Request.Context(),
		req.PreviousSentences,
		targetSentence,
		req.NextSentences,
		types.StandardLanguageCode(targetLang),
	)
	if err != nil {
		response.R(c, response.Response{Error: -1, Msg: err.Error(), Data: nil})
		return
	}

	response.R(c, response.Response{
		Error: 0,
		Msg:   "成功",
		Data: &dto.TranslateLineResData{
			Text:  text,
			Model: model,
		},
	})
}

