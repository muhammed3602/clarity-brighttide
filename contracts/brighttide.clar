;; BrightTide Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-goal-not-met (err u103))
(define-constant err-campaign-ended (err u104))

;; Data variables
(define-data-var campaign-id-nonce uint u0)

;; Define reward tiers
(define-map reward-tiers uint {
  name: (string-ascii 20),
  min-amount: uint
})

;; Campaign data structure
(define-map campaigns uint {
  title: (string-ascii 100),
  creator: principal,
  goal: uint,
  deadline: uint,
  current-amount: uint,
  is-active: bool
})

;; Donor records
(define-map donor-contributions { campaign-id: uint, donor: principal } {
  amount: uint,
  reward-tier: uint
})

;; Public functions
(define-public (create-campaign (title (string-ascii 100)) (goal uint) (duration uint) (creator principal))
  (let ((new-id (+ (var-get campaign-id-nonce) u1)))
    (if (is-eq tx-sender creator)
      (begin
        (map-set campaigns new-id {
          title: title,
          creator: creator,
          goal: goal,
          deadline: (+ block-height duration),
          current-amount: u0,
          is-active: true
        })
        (var-set campaign-id-nonce new-id)
        (ok new-id))
      err-unauthorized)))

(define-public (donate (campaign-id uint) (amount uint))
  (let ((campaign (unwrap! (map-get? campaigns campaign-id) err-not-found)))
    (if (and (get is-active campaign) 
             (<= block-height (get deadline campaign)))
      (let ((new-amount (+ (get current-amount campaign) amount))
            (donor-key { campaign-id: campaign-id, donor: tx-sender }))
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set campaigns campaign-id 
          (merge campaign { current-amount: new-amount }))
        (map-set donor-contributions donor-key {
          amount: (default-to u0 (get amount (map-get? donor-contributions donor-key))),
          reward-tier: (determine-reward-tier amount)
        })
        (ok true))
      err-campaign-ended)))

(define-public (withdraw-funds (campaign-id uint))
  (let ((campaign (unwrap! (map-get? campaigns campaign-id) err-not-found)))
    (if (and (is-eq tx-sender (get creator campaign))
             (>= (get current-amount campaign) (get goal campaign)))
      (begin
        (try! (as-contract (stx-transfer? (get current-amount campaign) tx-sender (get creator campaign))))
        (map-set campaigns campaign-id 
          (merge campaign { is-active: false }))
        (ok true))
      err-goal-not-met)))

;; Read-only functions
(define-read-only (get-campaign-info (campaign-id uint))
  (ok (unwrap! (map-get? campaigns campaign-id) err-not-found)))

(define-read-only (get-donor-info (campaign-id uint) (donor principal))
  (ok (unwrap! (map-get? donor-contributions { campaign-id: campaign-id, donor: donor }) err-not-found)))

(define-read-only (determine-reward-tier (amount uint))
  (if (>= amount u1000)
    u3 ;; Gold tier
    (if (>= amount u500)
      u2 ;; Silver tier
      u1))) ;; Bronze tier
