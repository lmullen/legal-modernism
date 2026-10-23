package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"sort"
	"time"
)

// Detecting and linking: the dashboard of how the linker fared over a whole
// corpus, and the match tiers charted. Both pages fetch their data as JSON and
// draw it with Observable Plot; the vocabulary of statuses and tiers is handed
// to the page from vocabulary.go. The same pages serve both corpora, the
// treatises and the CAP opinions, which the linker treats alike.

// linkingCorpus is a citation ledger the linking pages report on: the
// treatises' (moml_citations) or the CAP opinions' (opinion_citations, issue
// #74). The two values below are the only ones. A page handler is bound to one
// when its route is registered, and an API maps its corpus parameter onto one,
// so the schema names spliced into the queries never come from a request.
type linkingCorpus struct {
	Key   string // "moml" or "cap", the value of the corpus parameter
	Label string // the corpus in words, for headings and the switch
	Base  string // the dashboard's URL; the tiers page is Base + "/tiers"
	// Linker is the program that writes the corpus's links, named on the
	// dashboard when it finds citations still unlinked.
	Linker string
	// ReporterPages is whether reporter names link to /reporters/{standard}.
	// That page's figures are the treatises', so only the MOML pages link.
	ReporterPages bool
	// Graph is whether the dashboard carries the comparison with CAP's own
	// citation graph (capgraph.go).
	Graph bool

	schema       string // the schema of the linking_dashboard_* views
	topReporters string // the view of spelling counts the whitelist extender reads
}

var (
	momlCorpus = linkingCorpus{
		Key: "moml", Label: "MOML treatises", Base: "/linking", Linker: "cite-linker",
		ReporterPages: true,
		schema:        "moml_citations", topReporters: "legalhist.top_reporters",
	}
	capCorpus = linkingCorpus{
		Key: "cap", Label: "CAP opinions", Base: "/linking/cap", Linker: "cite-linker-cap",
		Graph:  true,
		schema: "opinion_citations", topReporters: "opinion_citations.top_reporters",
	}
	corpora = []linkingCorpus{momlCorpus, capCorpus}
)

// rel qualifies a relation name with the corpus's schema.
func (c linkingCorpus) rel(name string) string { return c.schema + "." + name }

// corpusParam reads the corpus query parameter of an API or of the whitelist
// extender: empty or "moml" is the treatises, "cap" the opinions, and anything
// else is refused.
func corpusParam(r *http.Request) (linkingCorpus, bool) {
	switch r.URL.Query().Get("corpus") {
	case "", momlCorpus.Key:
		return momlCorpus, true
	case capCorpus.Key:
		return capCorpus, true
	}
	return linkingCorpus{}, false
}

// linkingPage is the data of the linking pages: the header, the corpus, which
// sub-page is showing (for the section's navigation), and the vocabulary the
// scripts label the statuses and tiers with. Graph is the comparison with
// CAP's graph, filled only on the CAP dashboard.
type linkingPage struct {
	Page
	Corpus       linkingCorpus
	Nav          string // "dashboard", "tiers" or "whitelist"
	Tiers        []TierInfo
	StatusOrder  []string
	StatusLabels map[string]string
	Graph        *capGraph
}

// newLinkingPage builds the data of one linking page. The crumbs run from the
// section to the corpus's dashboard to the page.
func newLinkingPage(c linkingCorpus, nav, title, crumb string) linkingPage {
	crumbs := []Crumb{{Label: "Detecting & linking", URL: "/linking"}, {Label: c.Label, URL: c.Base}, {Label: crumb}}
	if nav == "dashboard" {
		crumbs = []Crumb{{Label: "Detecting & linking", URL: "/linking"}, {Label: c.Label}}
	}
	return linkingPage{
		Page:         Page{Title: title, Section: "linking", Crumbs: crumbs},
		Corpus:       c,
		Nav:          nav,
		Tiers:        tierVocabulary,
		StatusOrder:  statusOrder,
		StatusLabels: statusLabels,
	}
}

// navLink is one button of the corpus switch.
type navLink struct {
	Label  string
	URL    string
	Active bool
}

// CorpusLinks is the corpus switch: the page being shown, in each corpus.
func (p linkingPage) CorpusLinks() []navLink {
	links := make([]navLink, len(corpora))
	for i, c := range corpora {
		u := c.Base
		switch p.Nav {
		case "tiers":
			u = c.TiersURL()
		case "whitelist":
			u = c.WhitelistURL()
		}
		links[i] = navLink{Label: c.Label, URL: u, Active: c.Key == p.Corpus.Key}
	}
	return links
}

// handleLinking renders a corpus's dashboard. The MOML page is a shell its
// script fills from the API; the CAP page adds the comparison with CAP's
// graph, read here so that a view not yet populated becomes a notice.
func (s *server) handleLinking(c linkingCorpus) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		title := "Linking dashboard"
		if c.Key != momlCorpus.Key {
			title = "Linking dashboard: " + c.Label
		}
		data := newLinkingPage(c, "dashboard", title, "Dashboard")
		if c.Graph {
			ctx, cancel := s.ctx(r, 60*time.Second)
			defer cancel()
			g, err := s.getCAPGraph(ctx, &data.Page)
			if err != nil {
				s.serverError(w, r, err, "comparing the links with CAP's graph")
				return
			}
			data.Graph = g
		}
		s.render(w, r, "linking.html", http.StatusOK, data)
	}
}

func (s *server) handleLinkingTiers(c linkingCorpus) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		title := "Match tiers"
		if c.Key != momlCorpus.Key {
			title = "Match tiers: " + c.Label
		}
		s.render(w, r, "linking_tiers.html", http.StatusOK, newLinkingPage(c, "tiers", title, "Match tiers"))
	}
}

// ReporterStats holds linked and no-match counts for a single reporter_standard.
type ReporterStats struct {
	Reporter    string `json:"reporter"`
	Linked      int    `json:"linked"`
	NoMatch     int    `json:"noMatch"`
	Unprocessed int    `json:"unprocessed"`
	UK          bool   `json:"uk"`
}

// DashboardData holds aggregated linking status data for the dashboard.
type DashboardData struct {
	LinkedCAP            int
	LinkedEnglishReports int
	LinkedCodeReporter   int
	// LinkedStub counts links to legalhist.stub_cases (issue #248). It is part
	// of TotalLinked: the dashboard measures citations found, and a stub link
	// is one, with match_tier splitting it out where the distinction matters.
	LinkedStub            int
	SkippedNotWhiteListed int
	NoMatch               int
	SkippedJunk           int
	SkippedStatute        int
	TotalRawCites         int
	// Unprocessed is the citations detected but not yet linked. It is normally
	// zero; anything else means the linker has not finished, and every
	// percentage on the dashboard is being computed over a partial run
	// (issue #296).
	Unprocessed   int
	Reporters     []ReporterStats    `json:"Reporters,omitempty"`
	Tiers         []TierStat         `json:"Tiers,omitempty"`
	ReporterTiers []ReporterTierStat `json:"ReporterTiers,omitempty"`
	// Names is how far the detected case names reach (issue #392): one row
	// per status, tier and source, from the corpus's case_name_summary view.
	// Nil until the view exists and is populated.
	Names []NameStat `json:"Names,omitempty"`
}

// NameStat is one row of a corpus's case_name_summary: the citations of one
// status and match tier whose case name was found one way, or not at all
// (Source empty). Tier is empty for the statuses that carry none.
type NameStat struct {
	Status string `json:"status"`
	Tier   string `json:"tier"`
	Source string `json:"source"`
	N      int    `json:"n"`
}

// getCaseNameSummary reads the corpus's case_name_summary view.
func (s *server) getCaseNameSummary(ctx context.Context, c linkingCorpus) ([]NameStat, error) {
	slog.Debug("querying case name summary view", "corpus", c.Key)
	rows, err := s.db.Query(ctx, `
		SELECT status, COALESCE(match_tier, ''), COALESCE(case_name_source, ''), n
		FROM `+c.rel("case_name_summary")+`
		ORDER BY n DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("querying case name summary: %w", err)
	}
	defer rows.Close()
	var results []NameStat
	for rows.Next() {
		var n NameStat
		if err := rows.Scan(&n.Status, &n.Tier, &n.Source, &n.N); err != nil {
			return nil, fmt.Errorf("scanning case name summary: %w", err)
		}
		results = append(results, n)
	}
	slog.Debug("fetched case name summary", "count", len(results))
	return results, rows.Err()
}

// TotalLinked returns the sum of all linked statuses.
func (d *DashboardData) TotalLinked() int {
	return d.LinkedCAP + d.LinkedEnglishReports + d.LinkedCodeReporter + d.LinkedStub
}

// loadReporterStats fills in d.Reporters from the per-reporter materialized
// view, ordered by total citations descending (linked + no_match + unprocessed).
func (s *server) loadReporterStats(ctx context.Context, c linkingCorpus, d *DashboardData) error {
	rows, err := s.db.Query(ctx, `
		SELECT reporter_standard, linked, no_match, unprocessed, uk
		FROM `+c.rel("linking_dashboard_reporters")+`
		ORDER BY linked + no_match + unprocessed DESC
	`)
	if err != nil {
		return fmt.Errorf("querying reporter stats: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var r ReporterStats
		if err := rows.Scan(&r.Reporter, &r.Linked, &r.NoMatch, &r.Unprocessed, &r.UK); err != nil {
			return fmt.Errorf("scanning reporter stats: %w", err)
		}
		d.Reporters = append(d.Reporters, r)
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("iterating reporter stats: %w", err)
	}
	slog.Debug("fetched reporter stats", "count", len(d.Reporters))
	return nil
}

func (s *server) getDashboardData(ctx context.Context, c linkingCorpus) (*DashboardData, error) {
	d := &DashboardData{}

	// Get summary metrics (total raw cites, per-status counts, and how many
	// citations are not yet linked at all) from the precomputed materialized
	// view. The view is refreshed by db/maintenance.sh, not by the linker;
	// reading it here is a small indexed scan instead of aggregating the
	// tens-of-millions-row citations_unlinked and citation_links tables on
	// every request.
	slog.Debug("querying linking dashboard summary view", "corpus", c.Key)
	rows, err := s.db.Query(ctx, `SELECT metric, n FROM `+c.rel("linking_dashboard_summary"))
	if err != nil {
		return nil, fmt.Errorf("querying dashboard summary: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var metric string
		var n int
		if err := rows.Scan(&metric, &n); err != nil {
			return nil, fmt.Errorf("scanning dashboard summary: %w", err)
		}
		switch metric {
		case "total_raw_cites":
			d.TotalRawCites = n
		case "linked_cap":
			d.LinkedCAP = n
		case "linked_english_reports":
			d.LinkedEnglishReports = n
		case "linked_code_reporter":
			d.LinkedCodeReporter = n
		case "linked_stub":
			d.LinkedStub = n
		case "skipped_not_whitelisted":
			d.SkippedNotWhiteListed = n
		case "no_match":
			d.NoMatch = n
		case "skipped_junk":
			d.SkippedJunk = n
		case "skipped_statute":
			d.SkippedStatute = n
		case "unprocessed":
			d.Unprocessed = n
		}
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterating dashboard summary: %w", err)
	}

	// The three sections below each read their own materialized view, and a
	// failure in any of them is not fatal. A view that a migration has just
	// recreated stays unpopulated until the next make db-maintenance and errors
	// when queried; the summary above is the substance of the page, so a section
	// that cannot be read degrades to empty rather than taking the page down.
	if err := s.loadReporterStats(ctx, c, d); err != nil {
		slog.Warn("reporter stats unavailable, rendering dashboard without them", "error", err)
	}
	if d.Tiers, err = s.getTierSummary(ctx, c); err != nil {
		slog.Warn("tier summary unavailable, rendering dashboard without it", "error", err)
	}
	if d.ReporterTiers, err = s.getReporterTiers(ctx, c); err != nil {
		slog.Warn("reporter tiers unavailable, rendering dashboard without them", "error", err)
	}
	if d.Names, err = s.getCaseNameSummary(ctx, c); err != nil {
		slog.Warn("case name summary unavailable, rendering dashboard without it", "error", err)
	}

	slog.Debug("dashboard data complete", "corpus", c.Key, "total_raw_cites", d.TotalRawCites, "total_linked", d.TotalLinked(),
		"reporters", len(d.Reporters), "tiers", len(d.Tiers), "reporter_tiers", len(d.ReporterTiers))
	return d, nil
}

// TierStat is one row of a corpus's linking_tier_summary: a linking status
// paired with the match_tier that says how far the linker got, its count, and
// its share of that status. Tier is empty for the statuses that never reach a
// probe and so carry no tier.
type TierStat struct {
	Status      string  `json:"status"`
	Tier        string  `json:"tier"`
	N           int     `json:"n"`
	PctOfStatus float64 `json:"pctOfStatus"`
}

// getTierSummary reads the corpus-wide status × match_tier breakdown. The view
// aggregates the corpus's linking_dashboard_tiers, which joins the whitelist,
// so it covers exactly the citations the linker probes — linked, no_match,
// skipped_statute, and unprocessed — and omits skipped_junk and
// skipped_not_whitelisted, which are turned away before any target is consulted.
func (s *server) getTierSummary(ctx context.Context, c linkingCorpus) ([]TierStat, error) {
	slog.Debug("querying linking tier summary view", "corpus", c.Key)
	rows, err := s.db.Query(ctx, `
		SELECT status, match_tier, n, pct_of_status
		FROM `+c.rel("linking_tier_summary")+`
		ORDER BY n DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("querying tier summary: %w", err)
	}
	defer rows.Close()

	var results []TierStat
	for rows.Next() {
		var t TierStat
		var tier *string
		if err := rows.Scan(&t.Status, &tier, &t.N, &t.PctOfStatus); err != nil {
			return nil, fmt.Errorf("scanning tier summary: %w", err)
		}
		if tier != nil {
			t.Tier = *tier
		}
		results = append(results, t)
	}
	slog.Debug("fetched tier summary", "count", len(results))
	return results, rows.Err()
}

// ReporterTierStat holds one reporter_standard's no_match citations broken down
// by the tier that says where the match failed. Tiers is keyed by match_tier.
type ReporterTierStat struct {
	Reporter string         `json:"reporter"`
	NoMatch  int            `json:"noMatch"`
	Tiers    map[string]int `json:"tiers"`
}

// getReporterTiers reads the failure tiers of every reporter's no_match pool and
// pivots them into one row per reporter, so the page can compare the shape of a
// reporter's failures — mostly volume_absent, mostly page_absent — rather than
// only their total.
func (s *server) getReporterTiers(ctx context.Context, c linkingCorpus) ([]ReporterTierStat, error) {
	slog.Debug("querying per-reporter failure tiers", "corpus", c.Key)
	rows, err := s.db.Query(ctx, `
		SELECT reporter_standard, match_tier, n
		FROM `+c.rel("linking_dashboard_tiers")+`
		WHERE status = 'no_match' AND match_tier IS NOT NULL
	`)
	if err != nil {
		return nil, fmt.Errorf("querying reporter tiers: %w", err)
	}
	defer rows.Close()

	byReporter := make(map[string]*ReporterTierStat)
	for rows.Next() {
		var reporter, tier string
		var n int
		if err := rows.Scan(&reporter, &tier, &n); err != nil {
			return nil, fmt.Errorf("scanning reporter tier: %w", err)
		}
		r, ok := byReporter[reporter]
		if !ok {
			r = &ReporterTierStat{Reporter: reporter, Tiers: make(map[string]int)}
			byReporter[reporter] = r
		}
		r.Tiers[tier] += n
		r.NoMatch += n
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterating reporter tiers: %w", err)
	}

	results := make([]ReporterTierStat, 0, len(byReporter))
	for _, r := range byReporter {
		results = append(results, *r)
	}
	sort.Slice(results, func(i, j int) bool {
		if results[i].NoMatch != results[j].NoMatch {
			return results[i].NoMatch > results[j].NoMatch
		}
		return results[i].Reporter < results[j].Reporter
	})
	slog.Debug("fetched reporter tiers", "count", len(results))
	return results, nil
}

// ReporterTierRow is one (reporter, status, tier) cell of a corpus's
// linking_dashboard_tiers in the tidy shape the tiers page
// stacks into a bar per reporter. Tier is empty for the statuses that never
// reach a probe and so carry no tier.
type ReporterTierRow struct {
	Reporter string `json:"reporter"`
	Status   string `json:"status"`
	Tier     string `json:"tier"`
	N        int    `json:"n"`
}

// TiersData is everything the tiers page shows: the corpus-wide status ×
// match_tier breakdown, and the same breakdown for every reporter.
type TiersData struct {
	Tiers     []TierStat        `json:"tiers"`
	Reporters []ReporterTierRow `json:"reporters"`
}

// getReporterTierRows reads every reporter's citations grouped by status and
// match tier. Unlike getReporterTiers, which keeps only the no_match pool for
// the dashboard's failure table, this covers every status the view holds, so a
// reporter's bar shows its links and its failures side by side. Rows come back
// with the heaviest reporter first and each reporter's cells together, largest
// first, which is the order the page draws them in.
func (s *server) getReporterTierRows(ctx context.Context, c linkingCorpus) ([]ReporterTierRow, error) {
	slog.Debug("querying per-reporter tier rows", "corpus", c.Key)
	rows, err := s.db.Query(ctx, `
		SELECT reporter_standard, COALESCE(status, 'unprocessed'), COALESCE(match_tier, ''), n
		FROM `+c.rel("linking_dashboard_tiers")+`
		ORDER BY sum(n) OVER (PARTITION BY reporter_standard) DESC, reporter_standard, n DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("querying reporter tier rows: %w", err)
	}
	defer rows.Close()

	var results []ReporterTierRow
	for rows.Next() {
		var r ReporterTierRow
		if err := rows.Scan(&r.Reporter, &r.Status, &r.Tier, &r.N); err != nil {
			return nil, fmt.Errorf("scanning reporter tier row: %w", err)
		}
		results = append(results, r)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterating reporter tier rows: %w", err)
	}
	slog.Debug("fetched reporter tier rows", "count", len(results))
	return results, nil
}

// getTiersData assembles the tiers page from linking_tier_summary and
// linking_dashboard_tiers. Both read the same materialized view, so unlike the
// dashboard's optional sections there is no partial page worth rendering: if
// the view is unpopulated, the page has nothing to show.
func (s *server) getTiersData(ctx context.Context, c linkingCorpus) (*TiersData, error) {
	tiers, err := s.getTierSummary(ctx, c)
	if err != nil {
		return nil, err
	}
	reporters, err := s.getReporterTierRows(ctx, c)
	if err != nil {
		return nil, err
	}
	return &TiersData{Tiers: tiers, Reporters: reporters}, nil
}

// writeJSON sends v as a JSON response cached for an hour, the refresh
// cadence of the views behind it.
func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Cache-Control", "max-age=3600")
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(v); err != nil {
		slog.Error("error encoding JSON", "error", err)
	}
}

// apiError answers a failed API request. A view that is missing or not yet
// populated is a 503 that says what to run, which the pages' scripts show;
// anything else is a 500, with the error in the log.
func apiError(w http.ResponseWriter, err error, msg string, c linkingCorpus) {
	if isUnavailable(err) {
		slog.Warn(msg, "corpus", c.Key, "error", err)
		http.Error(w, "The views behind this page are not populated yet. Run make db-maintenance.", http.StatusServiceUnavailable)
		return
	}
	slog.Error(msg, "corpus", c.Key, "error", err)
	http.Error(w, "Internal server error", http.StatusInternalServerError)
}

func (s *server) handleLinkingAPI(w http.ResponseWriter, r *http.Request) {
	c, ok := corpusParam(r)
	if !ok {
		http.Error(w, "corpus must be moml or cap", http.StatusBadRequest)
		return
	}
	ctx, cancel := s.ctx(r, 30*time.Second)
	defer cancel()

	data, err := s.getDashboardData(ctx, c)
	if err != nil {
		apiError(w, err, "error querying dashboard data", c)
		return
	}
	writeJSON(w, data)
}

func (s *server) handleTiersAPI(w http.ResponseWriter, r *http.Request) {
	c, ok := corpusParam(r)
	if !ok {
		http.Error(w, "corpus must be moml or cap", http.StatusBadRequest)
		return
	}
	ctx, cancel := s.ctx(r, 30*time.Second)
	defer cancel()

	data, err := s.getTiersData(ctx, c)
	if err != nil {
		apiError(w, err, "error querying tiers data", c)
		return
	}
	writeJSON(w, data)
}
