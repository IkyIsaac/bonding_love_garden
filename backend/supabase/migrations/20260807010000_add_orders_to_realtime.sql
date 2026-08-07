-- =============================================================================
-- Realtime for orders — found missing while building the mobile checkout
-- screen (Home/Family Realtime already covered sessions/notifications, but
-- checkout watches an order flip pending -> paid the same way, and orders
-- was never added to the publication). Same reasoning as the
-- sessions/notifications migration: publication membership only, no schema
-- change to the table itself.
-- =============================================================================

alter publication supabase_realtime add table orders;
