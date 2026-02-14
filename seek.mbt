///|
pub suberror SeekError {
  NotSupported
} derive(Show, Eq)

///|
pub fn SeekError::source_intact(self : SeekError) -> Bool {
  match self {
    SeekError::NotSupported => true
  }
}
