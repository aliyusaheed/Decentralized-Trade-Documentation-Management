;; Document Certification Contract
;; This contract verifies authenticity of trade documents

(define-data-var admin principal tx-sender)

;; Data structure for documents
(define-map documents
  { document-id: (string-ascii 64) }
  {
    exporter-id: (string-ascii 32),
    document-type: (string-ascii 50),
    hash: (buff 32),
    timestamp: uint,
    verified: bool,
    verifier: (optional principal)
  }
)

;; Document types
(define-constant INVOICE "INVOICE")
(define-constant PACKING_LIST "PACKING_LIST")
(define-constant BILL_OF_LADING "BILL_OF_LADING")
(define-constant CERTIFICATE_OF_ORIGIN "CERTIFICATE_OF_ORIGIN")

;; Public function to register a new document
(define-public (register-document
    (document-id (string-ascii 64))
    (exporter-id (string-ascii 32))
    (document-type (string-ascii 50))
    (document-hash (buff 32)))
  (begin
    (asserts! (is-none (map-get? documents { document-id: document-id })) (err u100))

    (map-set documents
      { document-id: document-id }
      {
        exporter-id: exporter-id,
        document-type: document-type,
        hash: document-hash,
        timestamp: block-height,
        verified: false,
        verifier: none
      }
    )
    (ok true)
  )
)

;; Public function to verify a document
(define-public (verify-document (document-id (string-ascii 64)))
  (let ((document (unwrap! (map-get? documents { document-id: document-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set documents
      { document-id: document-id }
      (merge document {
        verified: true,
        verifier: (some tx-sender)
      })
    )
    (ok true)
  )
)

;; Read-only function to check if a document is verified
(define-read-only (is-document-verified (document-id (string-ascii 64)))
  (match (map-get? documents { document-id: document-id })
    document (ok (get verified document))
    (err u404)
  )
)

;; Read-only function to get document details
(define-read-only (get-document-details (document-id (string-ascii 64)))
  (map-get? documents { document-id: document-id })
)

;; Read-only function to verify document hash
(define-read-only (verify-document-hash
    (document-id (string-ascii 64))
    (hash-to-verify (buff 32)))
  (match (map-get? documents { document-id: document-id })
    document (ok (is-eq (get hash document) hash-to-verify))
    (err u404)
  )
)

;; Function to change admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
