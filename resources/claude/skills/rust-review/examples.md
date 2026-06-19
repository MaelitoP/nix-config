# Example Review Comments (Rust)

Use these as a tone and quality reference. Terse, concrete, with an idiomatic fix.

## Good example — Reachable panic (blocking)

- **File:** `src/config.rs:42`
- **Title:** `unwrap()` on user-supplied config path panics on missing file
- **Why it matters:** `fs::read_to_string(path).unwrap()` aborts the thread when the path doesn't exist — which is normal user input, not an invariant. A library function panicking crashes its caller.
- **Recommendation:** Propagate as a `Result` and let `?` + a `From` impl convert the error:
  ```rust
  let contents = fs::read_to_string(&path)
      .map_err(|source| LoadError::Read { path: path.clone(), source })?;
  ```
- **Confidence:** high

## Good example — Lock held across await (blocking)

- **File:** `src/cache.rs:88`
- **Title:** `std::sync::Mutex` guard held across `.await` can deadlock and breaks `Send`
- **Why it matters:** `let mut g = self.map.lock().unwrap();` then `g.insert(k, fetch(k).await);` holds the guard across the `.await`. The future becomes non-`Send` (won't spawn on a multi-thread runtime) and the lock is held for the whole fetch. Clippy flags this as `await_holding_lock`.
- **Recommendation:** Fetch first, then take the lock for a short critical section:
  ```rust
  let value = fetch(k).await;
  self.map.lock().unwrap().insert(k, value);
  ```
- **Confidence:** high

## Good example — Detached task leak (blocking)

- **File:** `src/worker.rs:31`
- **Title:** `tokio::spawn` detached with no shutdown path leaks the task
- **Why it matters:** The spawned task loops on `loop { let job = rx.recv().await; handle(job).await; }` and ignores the `None` from a closed channel; its `JoinHandle` is dropped, so nothing can stop it. On shutdown it lives until the runtime ends — under churn this leaks tasks.
- **Recommendation:** Exit when the channel closes, and keep the handle (or a `CancellationToken`) so the owner can join/cancel:
  ```rust
  while let Some(job) = rx.recv().await {
      handle(job).await;
  }
  ```
- **Confidence:** high

## Good example — Library error type (suggestion)

- **File:** `src/lib.rs:17`
- **Title:** Public API returns `anyhow::Error`, erasing the variants callers need
- **Why it matters:** `pub fn load() -> anyhow::Result<Config>` forces every caller to string-match or treat all failures alike. `anyhow` is for binaries; a library should return a concrete error so callers can branch (`C-GOOD-ERR`).
- **Recommendation:** Define a `thiserror` enum and return it:
  ```rust
  #[derive(Debug, thiserror::Error)]
  pub enum LoadError {
      #[error("read config {path}")]
      Read { path: PathBuf, #[source] source: std::io::Error },
      #[error("parse config")]
      Parse(#[from] toml::de::Error),
  }
  pub fn load() -> Result<Config, LoadError> { ... }
  ```
- **Confidence:** high

## Good example — Idiom & naming (suggestion)

- **File:** `src/user.rs:12`
- **Title:** `get_name` getter prefix and `&String` parameter are non-idiomatic
- **Why it matters:** Rust getters drop the `get_` prefix (`C-GETTER`), and `&String` parameters force callers to own a `String` when `&str` accepts both (`C-CALLER-CONTROL`, Clippy `ptr_arg`).
- **Recommendation:** `fn name(&self) -> &str` for the getter; `fn set_label(&mut self, label: &str)` for the parameter.
- **Confidence:** high

## Good example — Consistency clearly labeled (suggestion)

- **File:** `src/parse.rs:21,47`
- **Title:** File transforms an `Option` with `match` in one place and a combinator in another
- **Why it matters:** Line 21 uses `match opt { Some(x) => x + 1, None => 0 }`; line 47 uses `other.map(|x| x + 1).unwrap_or(0)` for the same shape. The variety is noise; Clippy flags the `match` form as `manual_map`/`map_unwrap_or`.
- **Recommendation:** Use the combinator form in both (canonical in `consistency.md`): `opt.map(|x| x + 1).unwrap_or(0)`. Strong default, not a hard rule.
- **Confidence:** medium

## Good example — Design question handed off

- **File:** `src/pricing.rs:8`
- **Title:** `dyn PricingStrategy` trait object may be premature
- **Why it matters:** `Box<dyn PricingStrategy>` has one implementation and one caller; the dynamic dispatch and allocation add cost and indirection without a second strategy in sight.
- **Recommendation:** Use the concrete type (or a generic `<P: PricingStrategy>`) for now; introduce the trait object when a second pricing model actually lands.
- **Confidence:** medium
- → `/rust-expert Should pricing variation be a `dyn` trait object now, a generic bound, or deferred until a second model exists?`

## Bad example

> Naming could be better and you should probably handle that error.

Why this is bad:
- no file/line
- no explanation of impact
- no concrete idiomatic fix
- no severity, no confidence
