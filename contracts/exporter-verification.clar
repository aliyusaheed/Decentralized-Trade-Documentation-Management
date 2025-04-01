;; Customs Compliance Contract
;; This contract ensures adherence to import/export regulations

(define-data-var admin principal tx-sender)

;; Data structure for compliance records
(define-map compliance-records
  { shipment-id: (string-ascii 64) }
  {
    exporter-id: (string-ascii 32),
    importer-id: (string-ascii 32),
    origin-country: (string-ascii 50),
    destination-country: (string-ascii 50),
    hs-code: (string-ascii 20),
    documents-complete: bool,
    customs-approved: bool,
    timestamp: uint
  }
)

;; Public function to register a new shipment for compliance
(define-public (register-shipment
    (shipment-id (string-ascii 64))
    (exporter-id (string-ascii 32))
    (importer-id (string-ascii 32))
    (origin-country (string-ascii 50))
    (destination-country (string-ascii 50))
    (hs-code (string-ascii 20)))
  (begin
    (asserts! (is-none (map-get? compliance-records { shipment-id: shipment-id })) (err u100))

    (map-set compliance-records
      { shipment-id: shipment-id }
      {
        exporter-id: exporter-id,
        importer-id: importer-id,
        origin-country: origin-country,
        destination-country: destination-country,
        hs-code: hs-code,
        documents-complete: false,
        customs-approved: false,
        timestamp: block-height
      }
    )
    (ok true)
  )
)

;; Public function to mark documents as complete
(define-public (mark-documents-complete (shipment-id (string-ascii 64)))
  (let ((record (unwrap! (map-get? compliance-records { shipment-id: shipment-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set compliance-records
      { shipment-id: shipment-id }
      (merge record { documents-complete: true })
    )
    (ok true)
  )
)

;; Public function to approve customs
(define-public (approve-customs (shipment-id (string-ascii 64)))
  (let ((record (unwrap! (map-get? compliance-records { shipment-id: shipment-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (get documents-complete record) (err u101))

    (map-set compliance-records
      { shipment-id: shipment-id }
      (merge record { customs-approved: true })
    )
    (ok true)
  )
)

;; Read-only function to check if a shipment is customs approved
(define-read-only (is-customs-approved (shipment-id (string-ascii 64)))
  (match (map-get? compliance-records { shipment-id: shipment-id })
    record (ok (get customs-approved record))
    (err u404)
  )
)

;; Read-only function to get shipment compliance details
(define-read-only (get-compliance-details (shipment-id (string-ascii 64)))
  (map-get? compliance-records { shipment-id: shipment-id })
)

;; Function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
