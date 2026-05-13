package exercises

// Exercise — GORM model. ID is string because it comes from external API.
type Exercise struct {
	ID           string `gorm:"primaryKey"                   json:"id"`
	Name         string `gorm:"not null"                     json:"name"`
	MuscleGroup  string `gorm:"column:muscle_group;not null" json:"muscle_group"`
	Equipment    string `                                    json:"equipment,omitempty"`
	Instructions string `                                    json:"instructions,omitempty"`
	GifURL       string `gorm:"column:gif_url"               json:"gif_url,omitempty"`
}

func (Exercise) TableName() string {
	return "exercises"
}
