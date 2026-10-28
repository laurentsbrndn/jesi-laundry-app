package auth

import (
	"github.com/gofiber/fiber/v3"

	"jesi-laundry-app-server/internal/platform/httpx"
	"jesi-laundry-app-server/internal/platform/mailer"
	"jesi-laundry-app-server/internal/platform/middleware"
)

const retryAfterSeconds = 60

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) SetupStatus(c fiber.Ctx) error {
	exists, err := h.svc.SetupStatus(c.Context())
	if err != nil {
		return err
	}
	return httpx.OK(c, SetupStatusResponse{OwnerExists: exists})
}

func (h *Handler) RegisterOwner(c fiber.Ctx) error {
	var req RegisterOwnerRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	session, err := h.svc.RegisterOwner(c.Context(), req)
	if err != nil {
		return err
	}
	return httpx.Created(c, newSessionResponse(session))
}

func (h *Handler) Login(c fiber.Ctx) error {
	var req LoginRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	session, err := h.svc.Login(c.Context(), req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newSessionResponse(session))
}

func (h *Handler) Refresh(c fiber.Ctx) error {
	var req RefreshRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	session, err := h.svc.Refresh(c.Context(), req.RefreshToken)
	if err != nil {
		return err
	}
	return httpx.OK(c, newSessionResponse(session))
}

func (h *Handler) Logout(c fiber.Ctx) error {
	var req LogoutRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	if err := h.svc.Logout(c.Context(), req.RefreshToken); err != nil {
		return err
	}
	return httpx.NoContent(c)
}

func (h *Handler) ForgotPassword(c fiber.Ctx) error {
	var req ForgotPasswordRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	lang := mailer.NormalizeLang(c.Get(fiber.HeaderAcceptLanguage))
	if err := h.svc.ForgotPassword(c.Context(), req, lang); err != nil {
		return err
	}
	return httpx.OK(c, RetryAfterResponse{RetryAfterSeconds: retryAfterSeconds})
}

func (h *Handler) ResetPassword(c fiber.Ctx) error {
	var req ResetPasswordRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	if err := h.svc.ResetPassword(c.Context(), req); err != nil {
		return err
	}
	return httpx.NoContent(c)
}

// ---- /me ----

func (h *Handler) GetMe(c fiber.Ctx) error {
	p, err := middleware.PrincipalFrom(c)
	if err != nil {
		return err
	}
	user, err := h.svc.GetMe(c.Context(), p.UserID)
	if err != nil {
		return err
	}
	return httpx.OK(c, newUserResponse(user))
}

func (h *Handler) UpdateMe(c fiber.Ctx) error {
	p, err := middleware.PrincipalFrom(c)
	if err != nil {
		return err
	}
	var req UpdateMeRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	user, err := h.svc.UpdateMe(c.Context(), p.UserID, req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newUserResponse(user))
}

func (h *Handler) ChangePassword(c fiber.Ctx) error {
	p, err := middleware.PrincipalFrom(c)
	if err != nil {
		return err
	}
	var req ChangePasswordRequest
	if err := httpx.BindBody(c, &req); err != nil {
		return err
	}
	session, err := h.svc.ChangePassword(c.Context(), p.UserID, req)
	if err != nil {
		return err
	}
	return httpx.OK(c, newSessionResponse(session))
}
