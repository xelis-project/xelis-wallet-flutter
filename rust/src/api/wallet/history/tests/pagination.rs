use super::*;

#[test]
fn history_pagination_is_one_based() {
    let first_page = filter();
    let options = first_page.options().unwrap();
    assert_eq!(options.skip, Some(0));
    assert_eq!(options.limit, Some(10));

    let mut second_page = filter();
    second_page.page = 2;
    second_page.limit = Some(25);
    assert_eq!(second_page.options().unwrap().skip, Some(25));
}

#[test]
fn history_rejects_zero_page_and_limit() {
    let mut zero_page = filter();
    zero_page.page = 0;
    assert_eq!(
        zero_page.options().unwrap_err().to_string(),
        "Page must be at least 1"
    );

    let mut zero_limit = filter();
    zero_limit.limit = Some(0);
    assert_eq!(
        zero_limit.options().unwrap_err().to_string(),
        "Limit cannot be 0"
    );
}

#[test]
fn history_rejects_a_pagination_offset_overflow() {
    let mut overflowing = filter();
    overflowing.page = usize::MAX;
    overflowing.limit = Some(2);
    assert_eq!(
        overflowing.options().unwrap_err().to_string(),
        "Pagination offset is too large"
    );
}

#[test]
fn history_rejects_a_pagination_range_overflow() {
    let mut overflowing = filter();
    overflowing.page = usize::MAX / 2 + 1;
    overflowing.limit = Some(2);
    let mut options = overflowing.options().unwrap();
    assert_eq!(
        FilteredPagination::prepare(&mut options)
            .unwrap_err()
            .to_string(),
        "Pagination range is too large"
    );
}

#[test]
fn maximum_topoheight_normalizes_u64_max_to_no_upper_bound() {
    let mut bounded = filter();
    bounded.max_topoheight = Some(u64::MAX - 1);
    assert_eq!(
        bounded.options().unwrap().max_topoheight,
        Some(u64::MAX - 1)
    );

    bounded.max_topoheight = Some(u64::MAX);
    assert_eq!(bounded.options().unwrap().max_topoheight, None);
}
