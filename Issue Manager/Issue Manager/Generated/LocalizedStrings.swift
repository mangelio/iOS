// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {

  internal enum Alert {
    /// Abbrechen
    internal static let cancel = L10n.tr("Localizable", "alert.cancel")
    /// Mehr Informationen…
    internal static let moreInfo = L10n.tr("Localizable", "alert.more_info")
    /// OK
    internal static let okay = L10n.tr("Localizable", "alert.okay")
    internal enum ConnectionIssues {
      /// Es konnte keine Verbindung zum Dienst aufgebaut werden.
      internal static let message = L10n.tr("Localizable", "alert.connection_issues.message")
      /// Verbindungsproblem
      internal static let title = L10n.tr("Localizable", "alert.connection_issues.title")
    }
    internal enum InvalidSession {
      /// Bitte neu einloggen.
      internal static let message = L10n.tr("Localizable", "alert.invalid_session.message")
      /// Ungültige Sitzung!
      internal static let title = L10n.tr("Localizable", "alert.invalid_session.title")
    }
    internal enum OutdatedClient {
      /// Diese Version der App kann leider nicht mehr mit dem Server kommunizieren. Bitte das neuste Update installieren.
      internal static let message = L10n.tr("Localizable", "alert.outdated_client.message")
      /// Update erforderlich
      internal static let title = L10n.tr("Localizable", "alert.outdated_client.title")
    }
    internal enum PushFailed {
      /// Einige Änderungen auf dem Gerät konnten nicht erfolgreich an die Website hochgeladen werden. Dies betrifft die folgenden Pendenzen:\n\n%@
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "alert.push_failed.message", String(describing: p1))
      }
      /// Fehler beim Hochladen!
      internal static let title = L10n.tr("Localizable", "alert.push_failed.title")
    }
    internal enum UnknownSyncError {
      /// Beim Aktualisieren ist ein unbekannter Fehler aufgetreten. Bitte später noch einmal versuchen.\n\nFalls der Fehler bestehen bleibt, sollte der Text unter "Mehr Informationen…" dem Support behilflich sein
      internal static let message = L10n.tr("Localizable", "alert.unknown_sync_error.message")
      /// Unbekannter Fehler!
      internal static let title = L10n.tr("Localizable", "alert.unknown_sync_error.title")
    }
    internal enum UpgradeWiped {
      /// Willkommen in der neuen Version! Bitte erneut anmelden.
      internal static let message = L10n.tr("Localizable", "alert.upgrade_wiped.message")
      /// App aktualisiert
      internal static let title = L10n.tr("Localizable", "alert.upgrade_wiped.title")
    }
    internal enum Wiped {
      /// Die App wurde in den Originalzustand zurückversetzt. Bitte diese nun neu starten.
      internal static let message = L10n.tr("Localizable", "alert.wiped.message")
      /// App schliessen
      internal static let quit = L10n.tr("Localizable", "alert.wiped.quit")
      /// App zurückgesetzt!
      internal static let title = L10n.tr("Localizable", "alert.wiped.title")
    }
  }

  internal enum ErrorViewer {
    /// Fehlerdetails
    internal static let title = L10n.tr("Localizable", "error_viewer.title")
    internal enum PushFailed {
      /// Diese Änderungen verwerfen
      internal static let discardChanges = L10n.tr("Localizable", "error_viewer.push_failed.discard_changes")
      /// Einige Änderungen auf dem Gerät konnten nicht erfolgreich an die Website hochgeladen werden. Dies betrifft die folgenden Pendenzen:\n\n%@\n\nWeitere Details:\n\n%@
      internal static func message(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "error_viewer.push_failed.message", String(describing: p1), String(describing: p2))
      }
      internal enum ChangesDiscarded {
        /// Bitte nun erneut das Synchronisieren versuchen.
        internal static let message = L10n.tr("Localizable", "error_viewer.push_failed.changes_discarded.message")
        /// Änderungen verworfen!
        internal static let title = L10n.tr("Localizable", "error_viewer.push_failed.changes_discarded.title")
      }
      internal enum Stage {
        /// Neue Pendenz Hochladen
        internal static let create = L10n.tr("Localizable", "error_viewer.push_failed.stage.create")
        /// Pendenz Löschen
        internal static let deletion = L10n.tr("Localizable", "error_viewer.push_failed.stage.deletion")
        /// Bild Hochladen
        internal static let imageUpload = L10n.tr("Localizable", "error_viewer.push_failed.stage.image_upload")
        /// Details Hochladen
        internal static let patch = L10n.tr("Localizable", "error_viewer.push_failed.stage.patch")
      }
    }
    internal enum UnknownError {
      /// Beim Aktualisieren ist ein unbekannter Fehler aufgetreten. Folgende Informationen sollten dem Support beim Diagnostizieren helfen:\n\n%@
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "error_viewer.unknown_error.message", String(describing: p1))
      }
    }
    internal enum WipeAllData {
      /// App zurücksetzen
      internal static let button = L10n.tr("Localizable", "error_viewer.wipe_all_data.button")
      /// Abbrechen
      internal static let cancel = L10n.tr("Localizable", "error_viewer.wipe_all_data.cancel")
      /// Alles Löschen
      internal static let confirm = L10n.tr("Localizable", "error_viewer.wipe_all_data.confirm")
      /// Es werden alle Daten gelöscht, die nicht auf der Website sind. Fortfahren?
      internal static let warning = L10n.tr("Localizable", "error_viewer.wipe_all_data.warning")
    }
  }

  internal enum Issue {
    /// Unternehmer
    internal static let craftsman = L10n.tr("Localizable", "issue.craftsman")
    /// Name
    internal static let craftsmanName = L10n.tr("Localizable", "issue.craftsman_name")
    /// Beschreibung
    internal static let description = L10n.tr("Localizable", "issue.description")
    /// Im Abnahmemodus aufgenommen
    internal static let isClientMode = L10n.tr("Localizable", "issue.is_client_mode")
    /// Kein Unternehmer
    internal static let noCraftsman = L10n.tr("Localizable", "issue.no_craftsman")
    /// Keine Beschreibung
    internal static let noDescription = L10n.tr("Localizable", "issue.no_description")
    /// Status
    internal static let status = L10n.tr("Localizable", "issue.status")
    /// Gewerk
    internal static let trade = L10n.tr("Localizable", "issue.trade")
    /// neu
    internal static let unregistered = L10n.tr("Localizable", "issue.unregistered")
    internal enum Status {
      /// Abgeschlossen
      internal static let closed = L10n.tr("Localizable", "issue.status.closed")
      /// Geschlossen von %@
      internal static func closedBy(_ p1: Any) -> String {
        return L10n.tr("Localizable", "issue.status.closed_by", String(describing: p1))
      }
      /// Neu
      internal static let new = L10n.tr("Localizable", "issue.status.new")
      /// Im Verzeichnis
      internal static let registered = L10n.tr("Localizable", "issue.status.registered")
      /// Registriert von %@
      internal static func registeredBy(_ p1: Any) -> String {
        return L10n.tr("Localizable", "issue.status.registered_by", String(describing: p1))
      }
      /// Zur Inspektion
      internal static let resolved = L10n.tr("Localizable", "issue.status.resolved")
      /// Umgesetzt von %@
      internal static func resolvedBy(_ p1: Any) -> String {
        return L10n.tr("Localizable", "issue.status.resolved_by", String(describing: p1))
      }
      /// [unbekannt]
      internal static let unknownEntity = L10n.tr("Localizable", "issue.status.unknown_entity")
    }
  }

  internal enum Login {
    /// Einloggen
    internal static let connectToWebsite = L10n.tr("Localizable", "login.connect_to_website")
    /// Jetzt registrieren
    internal static let register = L10n.tr("Localizable", "login.register")
    internal enum Alert {
      internal enum LoginError {
        /// Beim Einloggen ist ein Fehler aufgetreten.
        internal static let message = L10n.tr("Localizable", "login.alert.login_error.message")
        /// Unbekannter Fehler!
        internal static let title = L10n.tr("Localizable", "login.alert.login_error.title")
      }
    }
    internal enum Placeholder {
      /// Website
      internal static let website = L10n.tr("Localizable", "login.placeholder.website")
    }
    internal enum Register {
      /// Noch nicht registriert?
      internal static let header = L10n.tr("Localizable", "login.register.header")
    }
    internal enum Scan {
      /// Abbrechen
      internal static let cancel = L10n.tr("Localizable", "login.scan.cancel")
      /// Dazu auf der Website auf „mit App verbinden“ klicken (in der Baustellenauswahl oben links).
      internal static let instructions = L10n.tr("Localizable", "login.scan.instructions")
      /// Login-Code Scannen
      internal static let title = L10n.tr("Localizable", "login.scan.title")
    }
  }

  internal enum Map {
    /// Der Bauplan konnte nicht geladen werden!
    internal static let couldNotLoad = L10n.tr("Localizable", "map.could_not_load")
    /// Pendenz ohne Platzierung erfassen
    internal static let newUnpositionedIssue = L10n.tr("Localizable", "map.new_unpositioned_issue")
    /// Wähle links einen Bereich aus, um hier den zugehörigen Bauplan zu sehen.
    internal static let noMapSelected = L10n.tr("Localizable", "map.no_map_selected")
    /// Der Bereich "%@" hat keinen zugehörigen Bauplan.
    internal static func noPdf(_ p1: Any) -> String {
      return L10n.tr("Localizable", "map.no_pdf", String(describing: p1))
    }
    /// Bauplan wird geladen…
    internal static let pdfLoading = L10n.tr("Localizable", "map.pdf_loading")
    /// Bauplan
    internal static let title = L10n.tr("Localizable", "map.title")
    internal enum IssueList {
      /// Details anzeigen
      internal static let showDetails = L10n.tr("Localizable", "map.issue_list.show_details")
      /// Auf Bauplan anzeigen
      internal static let showInMap = L10n.tr("Localizable", "map.issue_list.show_in_map")
      /// %@ Pendenzen offen; %@ insgesamt
      internal static func summary(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "map.issue_list.summary", String(describing: p1), String(describing: p2))
      }
      /// Filter aktiv: %@/%@ Pendenzen angezeigt
      internal static func summaryFiltered(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "map.issue_list.summary_filtered", String(describing: p1), String(describing: p2))
      }
    }
    internal enum IssuePositioner {
      /// Abbrechen
      internal static let cancel = L10n.tr("Localizable", "map.issue_positioner.cancel")
      /// Weiter
      internal static let `continue` = L10n.tr("Localizable", "map.issue_positioner.continue")
    }
    internal enum StatusFilter {
      /// Es werden alle Pendenzen angezeigt.
      internal static let allSelected = L10n.tr("Localizable", "map.status_filter.all_selected")
      /// Es werden keine Pendenzen angezeigt.
      internal static let noneSelected = L10n.tr("Localizable", "map.status_filter.none_selected")
      /// Es werden nur Pendenzen mit einem der ausgewählten Status angezeigt.
      internal static let someSelected = L10n.tr("Localizable", "map.status_filter.some_selected")
      /// Filter nach Status
      internal static let title = L10n.tr("Localizable", "map.status_filter.title")
    }
  }

  internal enum MapList {
    internal enum MapRemoved {
      /// Schliessen
      internal static let dismiss = L10n.tr("Localizable", "map_list.map_removed.dismiss")
      /// Dieser Bereich existiert nicht mehr.
      internal static let message = L10n.tr("Localizable", "map_list.map_removed.message")
      /// Bereich entfernt!
      internal static let title = L10n.tr("Localizable", "map_list.map_removed.title")
    }
    internal enum MapSummary {
      /// %@ offene Pendenzen
      internal static func openIssues(_ p1: Any) -> String {
        return L10n.tr("Localizable", "map_list.map_summary.open_issues", String(describing: p1))
      }
    }
    internal enum RemovedFromMap {
      /// Schliessen
      internal static let dismiss = L10n.tr("Localizable", "map_list.removed_from_map.dismiss")
      /// Diese Baustelle ist diesem Account nicht mehr zugänglich. Auf der Website kann dies unter "Baustelle auswählen" verändert werden.
      internal static let message = L10n.tr("Localizable", "map_list.removed_from_map.message")
      /// Kein Zugriff!
      internal static let title = L10n.tr("Localizable", "map_list.removed_from_map.title")
    }
    internal enum Section {
      /// Untergeordnete Bereiche
      internal static let childMaps = L10n.tr("Localizable", "map_list.section.child_maps")
      /// Dieser Bereich
      internal static let thisMap = L10n.tr("Localizable", "map_list.section.this_map")
    }
  }

  internal enum Markup {
    /// Zeichnen
    internal static let title = L10n.tr("Localizable", "markup.title")
  }

  internal enum Register {
    /// Zurück zum Login
    internal static let backToLogin = L10n.tr("Localizable", "register.back_to_login")
    /// Registrieren
    internal static let createAccount = L10n.tr("Localizable", "register.create_account")
    /// Auf anderer Website registrieren
    internal static let customizeWebsite = L10n.tr("Localizable", "register.customize_website")
    /// Es wird jetzt eine E-Mail verschickt, über welche der Account fertig erstellt werden kann.
    internal static let emailExplanation = L10n.tr("Localizable", "register.email_explanation")
    internal enum Alert {
      internal enum InvalidEmail {
        /// '%@' ist keine gültige E-Mail-Adresse.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "register.alert.invalid_email.message", String(describing: p1))
        }
        /// Ungültige E-Mail!
        internal static let title = L10n.tr("Localizable", "register.alert.invalid_email.title")
      }
      internal enum InvalidWebsite {
        /// '%@' ist keine gültige Web-Adresse.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "register.alert.invalid_website.message", String(describing: p1))
        }
        /// Ungültige Website!
        internal static let title = L10n.tr("Localizable", "register.alert.invalid_website.title")
      }
      internal enum UnknownError {
        /// Es ist beim Kommunizieren mit der Website ein unbekannter Fehler aufgetreten.\n\nFalls der Fehler bestehen bleibt, könnte der folgende Text dem Support behilflich sein:\n%@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "register.alert.unknown_error.message", String(describing: p1))
        }
        /// Fehler beim Registrieren!
        internal static let title = L10n.tr("Localizable", "register.alert.unknown_error.title")
      }
    }
    internal enum Placeholder {
      /// E-Mail
      internal static let email = L10n.tr("Localizable", "register.placeholder.email")
      /// Website
      internal static let website = L10n.tr("Localizable", "register.placeholder.website")
    }
  }

  internal enum SiteList {
    /// Ausloggen
    internal static let logOut = L10n.tr("Localizable", "site_list.log_out")
    /// Noch keine Daten geladen! Hier herunterziehen, um mit dem Server zu synchronisieren.
    internal static let refreshHint = L10n.tr("Localizable", "site_list.refresh_hint")
    /// Baustellen
    internal static let title = L10n.tr("Localizable", "site_list.title")
    /// Willkommen, %@
    internal static func welcome(_ p1: Any) -> String {
      return L10n.tr("Localizable", "site_list.welcome", String(describing: p1))
    }
    internal enum ClientMode {
      /// Im Abnahmemodus werden nur die Pendenzen angezeigt, die auch im Abnahmemodus erfasst wurden.
      internal static let description = L10n.tr("Localizable", "site_list.client_mode.description")
      /// Abnahmemodus
      internal static let title = L10n.tr("Localizable", "site_list.client_mode.title")
    }
    internal enum FileProgress {
      /// %@/%@ Pendenzbilder geladen…
      internal static func determinate(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "site_list.file_progress.determinate", String(describing: p1), String(describing: p2))
      }
      /// Pendenzbilder werden geladen…
      internal static let indeterminate = L10n.tr("Localizable", "site_list.file_progress.indeterminate")
    }
    internal enum SiteSummary {
      /// %@ offene Pendenzen
      internal static func openIssues(_ p1: Any) -> String {
        return L10n.tr("Localizable", "site_list.site_summary.open_issues", String(describing: p1))
      }
      /// %@ insgesamt
      internal static func totalIssues(_ p1: Any) -> String {
        return L10n.tr("Localizable", "site_list.site_summary.total_issues", String(describing: p1))
      }
    }
  }

  internal enum Sync {
    internal enum Progress {
      /// Baustellenfotos laden: %@
      internal static func downloadingConstructionSiteFiles(_ p1: Any) -> String {
        return L10n.tr("Localizable", "sync.progress.downloading_construction_site_files", String(describing: p1))
      }
      /// Grundrisse laden: %@
      internal static func downloadingMapFiles(_ p1: Any) -> String {
        return L10n.tr("Localizable", "sync.progress.downloading_map_files", String(describing: p1))
      }
      /// Baustellen laden…
      internal static let fetchingTopLevelObjects = L10n.tr("Localizable", "sync.progress.fetching_top_level_objects")
      /// Pendenzen laden: %@
      internal static func pullingSiteData(_ p1: Any) -> String {
        return L10n.tr("Localizable", "sync.progress.pulling_site_data", String(describing: p1))
      }
      /// Änderungen hochladen…
      internal static let pushingLocalChanges = L10n.tr("Localizable", "sync.progress.pushing_local_changes")
      internal enum FileProgress {
        /// %@/%@
        internal static func determinate(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "sync.progress.file_progress.determinate", String(describing: p1), String(describing: p2))
        }
        /// fertig!
        internal static let done = L10n.tr("Localizable", "sync.progress.file_progress.done")
        /// …
        internal static let indeterminate = L10n.tr("Localizable", "sync.progress.file_progress.indeterminate")
      }
    }
  }

  internal enum ViewIssue {
    /// Aktionen
    internal static let actions = L10n.tr("Localizable", "view_issue.actions")
    /// Tippen, um ein Foto zu machen.
    internal static let cameraControlHint = L10n.tr("Localizable", "view_issue.camera_control_hint")
    /// Die Kamera konnte nicht aktiviert werden!
    internal static let couldNotActivateCamera = L10n.tr("Localizable", "view_issue.could_not_activate_camera")
    /// Unternehmer
    internal static let craftsman = L10n.tr("Localizable", "view_issue.craftsman")
    /// Beschreibung
    internal static let description = L10n.tr("Localizable", "view_issue.description")
    /// Details
    internal static let details = L10n.tr("Localizable", "view_issue.details")
    /// Foto
    internal static let image = L10n.tr("Localizable", "view_issue.image")
    /// Im Abnahmemodus aufgenommen
    internal static let isClientMode = L10n.tr("Localizable", "view_issue.is_client_mode")
    /// Auf Foto zeichnen
    internal static let markup = L10n.tr("Localizable", "view_issue.markup")
    /// Keine passenden Vorschläge
    internal static let noSuggestions = L10n.tr("Localizable", "view_issue.no_suggestions")
    /// Kein Gewerk
    internal static let noTrade = L10n.tr("Localizable", "view_issue.no_trade")
    /// Erneut versuchen
    internal static let retryCamera = L10n.tr("Localizable", "view_issue.retry_camera")
    /// Diese Pendenz wurde vom Unternehmer als umgesetzt markiert.
    internal static let reviewExplanation = L10n.tr("Localizable", "view_issue.review_explanation")
    /// Neue Pendenz
    internal static let titleCreating = L10n.tr("Localizable", "view_issue.title_creating")
    /// Pendenz bearbeiten
    internal static let titleEditing = L10n.tr("Localizable", "view_issue.title_editing")
    /// Details
    internal static let titleViewing = L10n.tr("Localizable", "view_issue.title_viewing")
    internal enum Action {
      /// Pendenz schliessen
      internal static let close = L10n.tr("Localizable", "view_issue.action.close")
      /// Pendenz wiedereröffnen
      internal static let reopen = L10n.tr("Localizable", "view_issue.action.reopen")
      /// Markierung zurücksetzen
      internal static let resetResolution = L10n.tr("Localizable", "view_issue.action.reset_resolution")
    }
    internal enum CouldNotOpenLibrary {
      /// Um die Fotoauswahl zu öffnen, braucht diese App in den Einstellungen Zugriff auf deine Fotos.
      internal static let message = L10n.tr("Localizable", "view_issue.could_not_open_library.message")
      /// Fotoauswahl nicht möglich!
      internal static let title = L10n.tr("Localizable", "view_issue.could_not_open_library.title")
    }
    internal enum CouldNotSaveImage {
      /// Das Bild konnte nicht abgespeichert werden!
      internal static let title = L10n.tr("Localizable", "view_issue.could_not_save_image.title")
    }
    internal enum CouldNotTakePicture {
      /// Fotoaufnahme fehlgeschlagen!
      internal static let title = L10n.tr("Localizable", "view_issue.could_not_take_picture.title")
    }
    internal enum ImagePlaceholder {
      /// Bild noch nicht geladen.
      internal static let loading = L10n.tr("Localizable", "view_issue.image_placeholder.loading")
      /// Kein Foto gesetzt
      internal static let notSet = L10n.tr("Localizable", "view_issue.image_placeholder.not_set")
    }
    internal enum IsClientMode {
      /// Nein
      internal static let `false` = L10n.tr("Localizable", "view_issue.is_client_mode.false")
      /// Ja
      internal static let `true` = L10n.tr("Localizable", "view_issue.is_client_mode.true")
    }
    internal enum SelectCraftsman {
      /// Kein Unternehmer
      internal static let `none` = L10n.tr("Localizable", "view_issue.select_craftsman.none")
      /// Unternehmer
      internal static let title = L10n.tr("Localizable", "view_issue.select_craftsman.title")
    }
    internal enum SelectTrade {
      /// Kein Gewerk
      internal static let `none` = L10n.tr("Localizable", "view_issue.select_trade.none")
      /// Gewerke
      internal static let title = L10n.tr("Localizable", "view_issue.select_trade.title")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
