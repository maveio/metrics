defmodule MaveMetrics.Repo.Migrations.CreateEventData do
  use Ecto.Migration
  import Timescale.Migration

  def up do
    # https://hexdocs.pm/timescale/intro.html#building-a-health-tracker
    execute "CREATE TYPE video_event AS ENUM (
      'durationchange',
      'loadedmetadata',
      'loadeddata',
      'canplay',
      'canplaythrough',
      'play',
      'playing',
      'pause',
      'seeked',
      'ratechange',
      'volumechange',
      'rebuffering_start',
      'rebuffering_end',
      'playback_failure',
      'fullscreen_enter',
      'fullscreen_exit',
      'source_set',
      'track_set'
      )"

    create_if_not_exists table(:events, primary_key: false) do
      add :name, :video_event, null: false, primary_key: true
      add :timestamp, :utc_datetime_usec, null: false, primary_key: true
      add :session_id, references(:sessions), null: false, primary_key: true
    end

    create_if_not_exists index(:events, [:session_id])
    create_if_not_exists unique_index(:events, [:name, :timestamp, :session_id])

    create_hypertable(:events, :timestamp)


    # triggered when `native_pause` is triggered (which is also triggered when video ends or when user seeks or user closes the page):

    create_if_not_exists table(:plays, primary_key: false) do
      add :timestamp, :utc_datetime_usec, null: false, primary_key: true
      add :session_id, references(:sessions), null: false, primary_key: true

      add :from, :float, null: false
      add :to, :float

      add :elapsed_time, :float
    end

    create_if_not_exists index(:plays, [:session_id])
    create_if_not_exists unique_index(:plays, [:session_id, :timestamp])
    create_hypertable(:plays, :timestamp)


    # sources

    # create_if_not_exists table(:sources, primary_key: false) do
    #   add :timestamp, :utc_datetime_usec, null: false, primary_key: true
    #   add :session_id, references(:sessions), null: false, primary_key: true

    #   add :source_url, :map, null: false

    #   add :bitrate, :int
    #   add :width, :int
    #   add :height, :int
    #   add :codec, :string
    # end

    # create_if_not_exists index(:sources, [:session_id])
    # create_if_not_exists unique_index(:sources, [:session_id, :timestamp])
    # create_hypertable(:sources, :timestamp)

    # tracks

    execute "CREATE TYPE language_code AS ENUM ('af', 'am', 'ar', 'as', 'az', 'ba', 'be', 'bg', 'bn', 'bo', 'br', 'bs', 'ca', 'cs', 'cy', 'da', 'de', 'el', 'en', 'es', 'et', 'eu', 'fa', 'fi', 'fo', 'fr', 'gl', 'gu', 'ha', 'haw', 'hi', 'hr', 'ht', 'hu', 'hy', 'id', 'is', 'it', 'iw', 'ja', 'jw', 'ka', 'kk', 'km', 'kn', 'ko', 'la', 'lb', 'ln', 'lo', 'lt', 'lv', 'mg', 'mi', 'mk', 'ml', 'mn', 'mr', 'ms', 'mt', 'my', 'ne', 'nl', 'nn', 'no', 'oc', 'pa', 'pl', 'ps', 'pt', 'ro', 'ru', 'sa', 'sd', 'si', 'sk', 'sl', 'sn', 'so', 'sq', 'sr', 'su', 'sv', 'sw', 'ta', 'te', 'tg', 'th', 'tk', 'tl', 'tr', 'tt', 'uk', 'ur', 'uz', 'vi', 'yi', 'yo', 'zh')"

    create_if_not_exists table(:tracks, primary_key: false) do
      add :timestamp, :utc_datetime_usec, null: false, primary_key: true
      add :session_id, references(:sessions), null: false, primary_key: true

      add :language, :language_code
    end

    create_if_not_exists index(:tracks, [:session_id])
    create_if_not_exists unique_index(:tracks, [:session_id, :timestamp])
    create_hypertable(:tracks, :timestamp)
  end


  def down do
    drop table("tracks"), mode: :cascade
    drop table("sources"), mode: :cascade
    drop table("plays"), mode: :cascade
    drop table("events"), mode: :cascade
  end
end
